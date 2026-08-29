# sync_access.py
from zk import ZK
from zk.user import User
from zk.finger import Finger
import requests
from config import *

RAILS_API_BASE = "https://spine-fitness.com"
DEVICE_SN = "NFZ8253402448"


def get_device_audit():
    try:
        requests.get(RAILS_API_BASE, timeout=30)  # wake server
    except:
        pass
    try:
        response = requests.get(
            f"{RAILS_API_BASE}/api/device_audit",
            params={"compcode": COMP_CODE, "device_sn": DEVICE_SN},
            timeout=60
        )
        return response.json().get("mappings", [])
    except Exception as e:
        print(f"Could not fetch device audit: {e}")
        return []


def save_template_to_rails(device_user_id, uid, templates):
    try:
        template_data = [
            {"uid": t.uid, "fid": t.fid, "valid": t.valid, "template": list(t.template)}
            for t in templates
        ]
        response = requests.post(
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
        # Must return True only if Rails confirmed the save
        if response.status_code == 200:
            result = response.json()
            if result.get("status") == True:
                print(f"    Template saved for device_user_id={device_user_id}")
                return True
        print(f"    Template save returned unexpected response: {response.status_code} {response.text}")
        return False
    except Exception as e:
        print(f"    Template save failed: {e}")
        return False


def restore_user_to_device(conn, mapping):
    try:
        uid = mapping["uid"]
        device_user_id = mapping["device_user_id"]
        name = mapping.get("member_name", "Member")
        templates_data = mapping["templates"]

        if not uid or not templates_data:
            print(f"    No template data for {name}, skipping restore")
            return

        user_obj = User(
            uid=int(uid), name=name[:24], privilege=0,
            password='', group_id='', user_id=str(device_user_id), card=0
        )
        fingers = [
            Finger(uid=int(uid), fid=t["fid"], valid=t["valid"], template=bytes(t["template"]))
            for t in templates_data
        ]
        conn.save_user_template(user=user_obj, fingers=fingers)
        print(f"    Restored: {name} (device_user_id={device_user_id})")
    except Exception as e:
        print(f"    Could not restore {mapping.get('member_name')}: {e}")


def sync_device_access(dry_run=False):
    print(f"Starting access sync... (dry_run={dry_run})")

    all_mappings = get_device_audit()
    if not all_mappings:
        print("No mapping data from Rails, skipping sync")
        return

    mappings_by_device_user_id = {str(m["device_user_id"]): m for m in all_mappings}

    zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
            password=0, force_udp=False, ommit_ping=False)

    try:
        conn = zk.connect()
        conn.disable_device()

        device_users = conn.get_users()
        templates = conn.get_templates()
        templates_by_uid = {}
        for t in templates:
            templates_by_uid.setdefault(t.uid, []).append(t)

        present_device_user_ids = set()
        blocked_count = 0
        allowed_count = 0
        orphan_count = 0
        skipped_count = 0

        # --- PASS 1: walk every fingerprint actually on the device ---
        for user in device_users:
            if user.privilege == 14:
                continue  # never touch staff/admin

            device_user_id = str(user.user_id)
            present_device_user_ids.add(device_user_id)

            mapping = mappings_by_device_user_id.get(device_user_id)

            if not mapping:
                orphan_count += 1
                continue  # not mapped to anyone, leave alone

            if mapping["access"] == "DENY":
                tag = "active" if mapping["is_active_mapping"] else "duplicate"
                if dry_run:
                    print(f"  [DRY RUN] WOULD BLOCK: {mapping['member_name']} "
                          f"(device_user_id={device_user_id}, uid={user.uid}, {tag})")
                    blocked_count += 1
                else:
                    user_templates = templates_by_uid.get(user.uid, [])

                    # Two-phase: save template FIRST, only delete if save confirmed
                    if user_templates and mapping["is_active_mapping"]:
                        saved = save_template_to_rails(device_user_id, user.uid, user_templates)
                        if not saved:
                            print(f"  SKIPPED blocking {mapping['member_name']} "
                                  f"(device_user_id={device_user_id}) — "
                                  f"template save failed, will retry next sync")
                            skipped_count += 1
                            continue  # do NOT delete — retry next sync cycle

                    conn.delete_user(uid=user.uid)
                    print(f"  BLOCKED: {mapping['member_name']} "
                          f"(device_user_id={device_user_id}, uid={user.uid}, {tag})")
                    blocked_count += 1
            else:
                allowed_count += 1

        # --- PASS 2: restore anyone who renewed but isn't on device anymore ---
        for mapping in all_mappings:
            if not mapping["is_active_mapping"]:
                continue
            if mapping["access"] != "ALLOW":
                continue

            device_user_id = str(mapping["device_user_id"])
            if device_user_id in present_device_user_ids:
                continue

            if mapping["uid"] and mapping["templates"]:
                if dry_run:
                    print(f"  [DRY RUN] WOULD RESTORE: {mapping['member_name']} "
                          f"(device_user_id={device_user_id})")
                else:
                    restore_user_to_device(conn, mapping)
            else:
                print(f"  ALLOW but no stored template for {mapping['member_name']} "
                      f"(device_user_id={device_user_id}) — needs re-enrollment")

        conn.enable_device()
        print(f"\nSync complete. Allowed={allowed_count}, Blocked={blocked_count}, "
              f"Skipped={skipped_count}, Orphans (unmapped, untouched)={orphan_count}")

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
    import sys
    dry = "--dry-run" in sys.argv
    sync_device_access(dry_run=dry)