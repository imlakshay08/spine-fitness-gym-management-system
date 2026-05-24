# check_me.py
from zk import ZK
from config import *

zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT)
conn = zk.connect()
conn.disable_device()

users = conn.get_users()
templates = conn.get_templates()

print("=== USERS ===")
for u in users:
    if str(u.user_id) == '':
        print(f"FOUND YOU: uid={u.uid} user_id={u.user_id} name={u.name}")

print("\n=== YOUR TEMPLATES ===")
for t in templates:
    print(f"template uid={t.uid} fid={t.fid} valid={t.valid} size={len(t.template)}")

conn.enable_device()
conn.disconnect()