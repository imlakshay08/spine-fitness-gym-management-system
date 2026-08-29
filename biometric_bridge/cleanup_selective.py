# cleanup_selective.py
import csv
from zk import ZK
from config import *

zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
        password=0, force_udp=False, ommit_ping=False)

# Read the marked CSV
to_delete = []
to_keep = []

with open("biometric_users.csv", newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        uid = int(row["device_uid"])
        name = row["device_user_name"]
        device_user_id = row["device_user_id"]
        keep = row["keep"].strip().lower() == "yes"

        if keep:
            to_keep.append((uid, device_user_id, name))
        else:
            to_delete.append((uid, device_user_id, name))

print(f"Will KEEP {len(to_keep)} users:")
for uid, did, name in to_keep:
    print(f"  uid={uid} device_user_id={did} name={name}")

print(f"\nWill DELETE {len(to_delete)} users:")
for uid, did, name in to_delete[:10]:
    print(f"  uid={uid} device_user_id={did} name={name}")
if len(to_delete) > 10:
    print(f"  ... and {len(to_delete) - 10} more")

confirm = input(f"\nProceed with deleting {len(to_delete)} users from device? (yes/no): ")
if confirm.lower() != 'yes':
    print("Aborted.")
    exit()

try:
    conn = zk.connect()
    conn.disable_device()

    for uid, did, name in to_delete:
        try:
            conn.delete_user(uid=uid)
            print(f"  Deleted uid={uid} device_user_id={did} name={name}")
        except Exception as e:
            print(f"  Failed uid={uid}: {e}")

    conn.enable_device()
    print("\nDone!")

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