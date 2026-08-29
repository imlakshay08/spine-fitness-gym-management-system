# test_access.py
from zk import ZK

zk = ZK('192.168.31.151', port=4370, timeout=5)
conn = zk.connect()
conn.disable_device()

users = conn.get_users()
for u in users[:10]:  # just first 10
    print(f"uid={u.uid} user_id={u.user_id} name={u.name} privilege={u.privilege} group_id={getattr(u, 'group_id', 'N/A')}")

conn.enable_device()
conn.disconnect()