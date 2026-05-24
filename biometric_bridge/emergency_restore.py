# emergency_restore.py
from zk import ZK
from zk.user import User
from zk.finger import Finger
import requests
from config import *

RAILS_API_BASE = ""
DEVICE_SN = ""

zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
        password=0, force_udp=False, ommit_ping=False)

try:
    conn = zk.connect()
    conn.disable_device()

    response = requests.get(
        f"{RAILS_API_BASE}/api/access_status",
        params={"compcode": "SF", "device_sn": DEVICE_SN},
        timeout=60
    )
    users = response.json().get("users", [])

    for u in users:
        user_info = u.get("user_info", {})
        templates_data = user_info.get("templates")
        uid = user_info.get("uid")
        device_user_id = u.get("device_user_id")
        name = u.get("name", "Unknown")

        if uid and templates_data:
            user_obj = User(
                uid=int(uid),
                name=name[:24],
                privilege=0,
                password='',
                group_id='',
                user_id=str(device_user_id),
                card=0
            )
            fingers = [
                Finger(
                    uid=int(uid),
                    fid=t["fid"],
                    valid=t["valid"],
                    template=bytes(t["template"])
                )
                for t in templates_data
            ]
            conn.save_user_template(user=user_obj, fingers=fingers)
            print(f"Restored: {name} (device_user_id={device_user_id})")

    conn.enable_device()
    print("Done!")

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