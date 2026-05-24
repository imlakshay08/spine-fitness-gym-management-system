# sync_access.py
from zk import ZK
from zk.user import User
from zk.finger import Finger
import requests
from config import *

RAILS_API_BASE = "https://spine-fitness.com"
DEVICE_SN = "NFZ8253402448"

def get_access_status():
    try:
        # Wake up Render first with a quick ping
        requests.get(RAILS_API_BASE, timeout=30)
    except:
        pass
    try:
        response = requests.get(
            f"{RAILS_API_BASE}/api/access_status",
            params={"compcode": COMP_CODE, "device_sn": DEVICE_SN},
            timeout=60
        )
        return response.json().get("users", [])
    except Exception as e:
        print(f"Could not fetch access status: {e}")
        return []

def save_template_to_rails(device_user_id, uid, templates):
    try:
        template_data = [
            {
                "uid": t.uid,
                "fid": t.fid,
                "valid": t.valid,
                "template": list(t.template)
            }
            for t in templates
        ]
        requests.post(
            f"{RAILS_API_BASE}/api/biometric_mappings/save_template",
            json={
                "compcode": COMP_CODE,
                "device_user_id": device_user_id,
                "device_sn": DEVICE_SN,
                "uid": uid,
                "templates": template_data
            },
            timeout=60
        )
        print(f"    Template saved for device_user_id={device_user_id}")
    except Exception as e:
        print(f"    Could not save template: {e}")

def restore_user_to_device(conn, user_info):
    try:
        uid = user_info["uid"]
        device_user_id = user_info["device_user_id"]
        name = user_info["name"]
        templates_data = user_info["templates"]

        if not uid or not templates_data:
            print(f"    No template data for {name}, skipping restore")
            return

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
        print(f"    Restored: {name} (device_user_id={device_user_id})")
    except Exception as e:
        print(f"    Could not restore {user_info.get('name')}: {e}")

def sync_device_access():
    print("Starting access sync...")

    users_status = get_access_status()
    if not users_status:
        print("No data from Rails, skipping sync")
        return

    access_map = {str(u["device_user_id"]): u for u in users_status}

    zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
            password=0, force_udp=False, ommit_ping=False)

    try:
        conn = zk.connect()
        conn.disable_device()

        device_users = {str(u.user_id): u for u in conn.get_users()}
        templates = conn.get_templates()
        templates_by_uid = {}
        for t in templates:
            templates_by_uid.setdefault(t.uid, []).append(t)

        for device_user_id, status in access_map.items():
            access = status["access"]
            name = status.get("name", "Unknown")
            user_info = status.get("user_info", {})

            if device_user_id in device_users:
                user = device_users[device_user_id]

                # Never touch admins
                if user.privilege == 14:
                    print(f"  Skipping admin: {user.name}")
                    continue

                if access == "DENY":
                    # Save templates to Rails before deleting
                    user_templates = templates_by_uid.get(user.uid, [])
                    if user_templates:
                        save_template_to_rails(
                            device_user_id, user.uid, user_templates
                        )
                    else:
                        print(f"    No templates found on device for {name}")
                    conn.delete_user(uid=user.uid)
                    print(f"  BLOCKED: {name} (device_user_id={device_user_id})")

                else:
                    print(f"  ALLOWED: {name} (device_user_id={device_user_id})")

            else:
                # User not on device
                if access == "ALLOW":
                    # They were previously blocked — restore them
                    if user_info.get("uid") and user_info.get("templates"):
                        restore_user_to_device(conn, user_info)
                    else:
                        print(f"  ALLOW but no template stored for {name} — needs re-enrollment")
                else:
                    print(f"  DENY + not on device: {name} (already blocked)")

        conn.enable_device()
        print("Access sync complete.")

    except Exception as e:
        print(f"Sync error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        try:
            conn.enable_device()
            conn.disconnect()
        except:
            pass

if __name__ == "__main__":
    sync_device_access()