# wipe_except_keep.py
from zk import ZK
from config import *

KEEP_UIDS = {2, 8, 9, 127, 128}  # Vaneet, Vishal, Maaniit, Poonam, Kapil

zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
        password=0, force_udp=False, ommit_ping=False)

try:
    conn = zk.connect()
    conn.disable_device()

    users = conn.get_users()
    print(f"Total users on device: {len(users)}")

    to_keep = [u for u in users if u.uid in KEEP_UIDS]
    to_delete = [u for u in users if u.uid not in KEEP_UIDS]

    print(f"\nWill KEEP {len(to_keep)} users:")
    for u in to_keep:
        print(f"  uid={u.uid} device_user_id={u.user_id} name={u.name} privilege={u.privilege}")

    print(f"\nWill DELETE {len(to_delete)} users:")
    for u in to_delete[:10]:
        print(f"  uid={u.uid} device_user_id={u.user_id} name={u.name}")
    if len(to_delete) > 10:
        print(f"  ... and {len(to_delete) - 10} more")

    confirm = input(f"\nProceed with deleting {len(to_delete)} users from device? (yes/no): ")
    if confirm.lower() != 'yes':
        print("Aborted.")
        conn.enable_device()
        conn.disconnect()
        exit()

    for u in to_delete:
        try:
            conn.delete_user(uid=u.uid)
            print(f"  Deleted uid={u.uid} device_user_id={u.user_id} name={u.name}")
        except Exception as e:
            print(f"  Failed uid={u.uid}: {e}")

    conn.enable_device()
    print("\nDone!")

    # Final check
    remaining = conn.get_users()
    print(f"\nRemaining users on device: {len(remaining)}")
    for u in remaining:
        print(f"  uid={u.uid} device_user_id={u.user_id} name={u.name} privilege={u.privilege}")

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