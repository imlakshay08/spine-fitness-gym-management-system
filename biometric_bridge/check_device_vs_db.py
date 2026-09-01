# check_device_vs_db.py
from zk import ZK
import requests
from config import *

# Get all ACTIVE mappings from DB (uid only)
response = requests.get(
    f"{RAILS_API_BASE}/api/all_mappings",
    headers=API_HEADERS,
    params={"compcode": COMP_CODE, "device_sn": DEVICE_SN},
    timeout=60
)
active_mappings = response.json().get("mappings", [])
active_uids = set(str(m["uid"]) for m in active_mappings if m["uid"])
active_device_user_ids = set(str(m["device_user_id"]) for m in active_mappings)

print(f"Active mappings in DB: {len(active_mappings)}")
print(f"Active UIDs in DB: {sorted(active_uids, key=lambda x: int(x))}")

# Get all users on device
zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
        password=0, force_udp=False, ommit_ping=False)

conn = zk.connect()
conn.disable_device()
device_users = conn.get_users()
conn.enable_device()
conn.disconnect()

print(f"\nTotal users on device: {len(device_users)}")

# Find device users that are NOT in active DB mappings
orphans = []
for u in device_users:
    if u.privilege == 14:
        continue  # skip admins
    if str(u.user_id) not in active_device_user_ids:
        orphans.append(u)

print(f"\nOrphan users on device (no active DB mapping): {len(orphans)}")
for u in orphans:
    print(f"  uid={u.uid} device_user_id={u.user_id} name={u.name}")