from zk import ZK
from config import *

zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT)
conn = zk.connect()
try:
    for user in conn.get_users():
        print(user.uid, user.user_id, user.name, user.privilege)
finally:
    conn.disconnect()
