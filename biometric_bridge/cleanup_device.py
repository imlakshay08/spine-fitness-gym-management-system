# cleanup_device.py
from zk import ZK
from config import *

# These are SAFE to delete — confirmed duplicates and old replaced enrollments
# Verify this list yourself before running!

SAFE_TO_DELETE_UIDS = [

]

print(f"Will delete {len(SAFE_TO_DELETE_UIDS)} users from device.")
print("UIDs:", SAFE_TO_DELETE_UIDS)
confirm = input("\nProceed? (yes/no): ")
if confirm.lower() != 'yes':
    print("Aborted.")
    exit()

zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
        password=0, force_udp=False, ommit_ping=False)

try:
    conn = zk.connect()
    conn.disable_device()

    for uid in SAFE_TO_DELETE_UIDS:
        try:
            conn.delete_user(uid=uid)
            print(f"  ✓ Deleted uid={uid}")
        except Exception as e:
            print(f"  ✗ Failed uid={uid}: {e}")

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