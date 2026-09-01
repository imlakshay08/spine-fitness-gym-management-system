# deactivate_orphaned_mappings.py
import requests
from zk import ZK
from config import *

zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
        password=0, force_udp=False, ommit_ping=False)
conn = zk.connect()
device_user_ids = set(str(u.user_id) for u in conn.get_users())
conn.disconnect()

resp = requests.get(
    f"{RAILS_API_BASE}/api/device_audit",
    headers=API_HEADERS,
    params={"compcode": COMP_CODE, "device_sn": DEVICE_SN},
    timeout=60
)
mappings = resp.json().get("mappings", [])

to_deactivate = [
    m for m in mappings
    if m["is_active_mapping"] and str(m["device_user_id"]) not in device_user_ids
]

print(f"Found {len(to_deactivate)} active mappings pointing to deleted device users:")
for m in to_deactivate:
    print(f"  mapping_id={m['mapping_id']} member={m['member_name']} device_user_id={m['device_user_id']}")

confirm = input("\nDeactivate these mappings in DB? (yes/no): ")
if confirm.lower() == 'yes':
    for m in to_deactivate:
        r = requests.post(
            f"{RAILS_API_BASE}/api/member_mappings/deactivate",
            headers=API_HEADERS,
            json={"mapping_id": m["mapping_id"]},
            timeout=30
        )
        print(f"  Deactivated mapping_id={m['mapping_id']}: {r.json()}")