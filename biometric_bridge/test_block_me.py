# test_block_me.py
from zk import ZK
from zk.user import User
from zk.finger import Finger
import requests
from config import *

RAILS_API_BASE = "https://spine-fitness.com"
DEVICE_SN = "NFZ8253402448"
MY_DEVICE_USER_ID = "71"  # your device user id

def block_me():
    zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
            password=0, force_udp=False, ommit_ping=False)
    try:
        conn = zk.connect()
        conn.disable_device()

        # Get your user from device
        device_users = {str(u.user_id): u for u in conn.get_users()}
        
        if MY_DEVICE_USER_ID not in device_users:
            print(f"User {MY_DEVICE_USER_ID} not found on device!")
            return

        user = device_users[MY_DEVICE_USER_ID]
        print(f"Found: uid={user.uid} name={user.name}")

        # Get your templates
        templates = conn.get_templates()
        my_templates = [t for t in templates if t.uid == user.uid]
        print(f"Found {len(my_templates)} finger templates")

        if not my_templates:
            print("No templates found — cannot save and block safely!")
            return

        # Save templates to Rails first
        template_data = [
            {
                "uid": t.uid,
                "fid": t.fid,
                "valid": t.valid,
                "template": list(t.template)
            }
            for t in my_templates
        ]
        response = requests.post(
            f"{RAILS_API_BASE}/api/biometric_mappings/save_template",
            json={
                "compcode": "SF",
                "device_user_id": MY_DEVICE_USER_ID,
                "device_sn": DEVICE_SN,
                "uid": user.uid,
                "templates": template_data
            },
            timeout=60
        )
        print(f"Template saved to Rails: {response.json()}")

        # Delete from device
        conn.delete_user(uid=user.uid)
        print(f"BLOCKED: {user.name} deleted from device")

        conn.enable_device()
        print("Done! Go try your finger on the device — it should fail.")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        try:
            conn.enable_device()
            conn.disconnect()
        except:
            pass

block_me()