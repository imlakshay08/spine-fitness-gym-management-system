# enroll_api.py
from flask import Flask, request, jsonify
from flask_cors import CORS
from zk import ZK
from zk.user import User
import requests as req
from config import *
import threading
from sync_access import sync_device_access

app = Flask(__name__)
CORS(app)  # allow browser requests from any origin

RAILS_API_BASE = "https://spine-fitness.com"
DEVICE_SN = "NFZ8253402448"

# Single global lock — only one enrollment at a time, gym-wide
enrollment_lock = threading.Lock()

# Tracks the highest uid/device_user_id WE have handed out,
# even if the device hasn't registered the finger yet.
_last_issued = {"uid": 0, "device_user_id": 0}


def get_next_uid_and_user_id(conn, compcode):
    users = conn.get_users()
    device_max_uid = max([u.uid for u in users], default=0)
    existing_ids = [int(u.user_id) for u in users if str(u.user_id).isdigit()]
    device_max_user_id = max(existing_ids, default=0)

    # Also check DB history (active + inactive) — survives restarts
    try:
        resp = req.get(
            f"{RAILS_API_BASE}/api/max_ids",
            params={"compcode": compcode, "device_sn": DEVICE_SN},
            timeout=15
        ).json()
        db_max_uid = resp.get("max_uid", 0)
        db_max_user_id = resp.get("max_device_user_id", 0)
    except:
        db_max_uid = 0
        db_max_user_id = 0

    next_uid = max(device_max_uid, db_max_uid, _last_issued["uid"]) + 1
    next_user_id = max(device_max_user_id, db_max_user_id, _last_issued["device_user_id"]) + 1

    _last_issued["uid"] = next_uid
    _last_issued["device_user_id"] = next_user_id

    return next_uid, str(next_user_id)

def allocate_next_ids(compcode):
    resp = req.post(
        f"{RAILS_API_BASE}/api/biometric_mappings/allocate_ids",
        json={"compcode": compcode, "device_sn": DEVICE_SN},
        timeout=15
    ).json()
    return resp["uid"], resp["device_user_id"]

@app.route('/enroll', methods=['POST'])
def enroll():
    data        = request.json
    member_id   = data.get('member_id')
    member_name = data.get('member_name', 'Member')
    compcode    = data.get('compcode', 'SF')

    # Only one enrollment can run at a time across the whole gym
    if not enrollment_lock.acquire(blocking=False):
        return jsonify({
            'status': False,
            'message': 'Another enrollment is currently in progress. Please wait until that member finishes scanning, then try again.'
        }), 429

    zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
            password=0, force_udp=False, ommit_ping=False)
    try:
        conn = zk.connect()
        conn.disable_device()

        # Step 1: Find all existing mappings for this member and delete from device
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

        # Step 2: Deactivate all old mappings in Rails
        deact_resp = req.post(
            f"{RAILS_API_BASE}/api/member_mappings/deactivate_all",
            json={"compcode": compcode, "member_id": str(member_id)},
            timeout=30
        )
        print(f"deactivate_all response: {deact_resp.status_code} {deact_resp.text}")

        # Step 3: Create new user on device
        new_uid, new_device_user_id = allocate_next_ids(compcode)
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

        # Run sync in background so access status is corrected immediately
       # threading.Thread(target=sync_device_access, daemon=True).start()

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
        enrollment_lock.release()


@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': True, 'message': 'Enrollment API running'})


if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=False)