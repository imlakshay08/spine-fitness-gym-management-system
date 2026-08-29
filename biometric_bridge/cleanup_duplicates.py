# cleanup_duplicates.py
import requests
from zk import ZK
from config import *

RAILS_API_BASE = "https://spine-fitness.com"
DEVICE_SN = "NFZ8253402448"

# Step 1: Get all active mappings from Rails
response = requests.get(
    f"{RAILS_API_BASE}/api/access_status",
    params={"compcode": COMP_CODE, "device_sn": DEVICE_SN},
    timeout=60
)
users = response.json().get("users", [])

# Step 2: Find all mappings from DB grouped by member
response2 = requests.get(
    f"{RAILS_API_BASE}/api/all_mappings",
    params={"compcode": COMP_CODE, "device_sn": DEVICE_SN},
    timeout=60
)
all_mappings = response2.json().get("mappings", [])

# Group by member_id
from collections import defaultdict
by_member = defaultdict(list)
for m in all_mappings:
    by_member[m["member_id"]].append(m)

# Find members with duplicates
duplicates = {k: v for k, v in by_member.items() if len(v) > 1}

print(f"Found {len(duplicates)} members with duplicate mappings:")
for member_id, mappings in duplicates.items():
    print(f"\n  Member {member_id}: {len(mappings)} mappings")
    for m in mappings:
        print(f"    id={m['id']} device_user_id={m['device_user_id']} uid={m['uid']}")

if not duplicates:
    print("No duplicates found!")
    exit()

confirm = input("\nProceed with cleanup? This will delete old fingers from device and DB. (yes/no): ")
if confirm.lower() != 'yes':
    print("Aborted.")
    exit()

# Step 3: Connect to device and clean up
zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
        password=0, force_udp=False, ommit_ping=False)

try:
    conn = zk.connect()
    conn.disable_device()

    for member_id, mappings in duplicates.items():
        # Keep the latest (highest id), delete the rest
        mappings_sorted = sorted(mappings, key=lambda x: x["id"])
        to_delete = mappings_sorted[:-1]   # all except last
        to_keep   = mappings_sorted[-1]    # latest one

        print(f"\nMember {member_id}: keeping id={to_keep['id']} (uid={to_keep['uid']}), deleting {len(to_delete)} old ones")

        for m in to_delete:
            uid = m.get("uid")
            mapping_id = m.get("id")

            # Delete from device
            if uid:
                try:
                    conn.delete_user(uid=int(uid))
                    print(f"  ✓ Deleted from device: uid={uid}")
                except Exception as e:
                    print(f"  ✗ Could not delete uid={uid} from device: {e}")

            # Deactivate in DB
            try:
                requests.post(
                    f"{RAILS_API_BASE}/api/member_mappings/deactivate",
                    json={"mapping_id": mapping_id},
                    timeout=30
                )
                print(f"  ✓ Deactivated in DB: mapping_id={mapping_id}")
            except Exception as e:
                print(f"  ✗ Could not deactivate mapping_id={mapping_id}: {e}")

    conn.enable_device()
    print("\nCleanup complete!")

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