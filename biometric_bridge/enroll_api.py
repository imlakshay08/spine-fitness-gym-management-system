# enroll_api.py
from flask import Flask, request, jsonify
from flask_cors import CORS
from zk import ZK
from zk.user import User
import requests as req
from config import *
import threading

app = Flask(__name__)
CORS(app)  # allow browser requests from any origin

RAILS_API_BASE = ""
DEVICE_SN = ""

_enrollment_locks = {}
_locks_mutex = threading.Lock()

def get_member_lock(member_id):
    with _locks_mutex:
        if member_id not in _enrollment_locks:
            _enrollment_locks[member_id] = threading.Lock()
        return _enrollment_locks[member_id]


def get_next_uid_and_user_id(conn):
    users = conn.get_users()
    if not users:
        return 1, '1'
    max_uid = max(u.uid for u in users)
    existing_ids = [int(u.user_id) for u in users if str(u.user_id).isdigit()]
    max_user_id = max(existing_ids) if existing_ids else 0
    return max_uid + 1, str(max_user_id + 1)

@app.route('/enroll', methods=['POST'])
def enroll():
    data        = request.json
    member_id   = data.get('member_id')
    member_name = data.get('member_name', 'Member')
    compcode    = data.get('compcode', 'SF')

    zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
            password=0, force_udp=False, ommit_ping=False)

    try:
        conn = zk.connect()
        conn.disable_device()

        # ✅ Step 1: Find all existing mappings for this member and delete from device
        existing_mappings = req.get(
            f"{RAILS_API_BASE}/api/member_mappings",
            params={"compcode": compcode, "member_id": member_id},
            timeout=30
        ).json().get("mappings", [])

        for mapping in existing_mappings:
            uid = mapping.get("uid")
            if uid:
                try:
                    conn.delete_user(uid=int(uid))
                    print(f"Deleted old uid={uid} for member {member_id}")
                except:
                    pass  # already gone from device, that's fine

        # ✅ Step 2: Deactivate all old mappings in Rails
        req.post(
            f"{RAILS_API_BASE}/api/member_mappings/deactivate_all",
            json={"compcode": compcode, "member_id": member_id},
            timeout=30
        )

        # Step 3: Create new user on device
        new_uid, new_device_user_id = get_next_uid_and_user_id(conn)
        user_obj = User(
            uid=new_uid, name=member_name[:24], privilege=0,
            password='', group_id='', user_id=new_device_user_id, card=0
        )
        conn.save_user_template(user=user_obj, fingers=[])
        conn.enable_device()
        conn.enroll_user(uid=new_uid, temp_id=0)

        # Step 4: Save new mapping to Rails
        req.post(
            f"{RAILS_API_BASE}/api/biometric_mappings",
            json={
                'compcode': compcode, 'member_id': str(member_id),
                'device_user_id': new_device_user_id,
                'device_sn': DEVICE_SN, 'uid': new_uid
            },
            timeout=30
        )

        return jsonify({
            'status': True,
            'message': f'Old fingers removed — ask {member_name} to scan new finger now!',
            'device_user_id': new_device_user_id
        })

    except Exception as e:
        return jsonify({'status': False, 'message': str(e)}), 500
    finally:
        try:
            conn.enable_device()
            conn.disconnect()
        except:
            pass

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': True, 'message': 'Enrollment API running'})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=False)