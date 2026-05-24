import csv
from zk import ZK
from config import *

zk = ZK(
    DEVICE_IP,
    port=DEVICE_PORT,
    timeout=5,
    password=0,
    force_udp=False,
    ommit_ping=False
)

conn = zk.connect()
users = conn.get_users()

csv_file = "biometric_users.csv"

with open(csv_file, mode="w", newline="", encoding="utf-8") as file:
    writer = csv.writer(file)

    # CSV HEADER
    writer.writerow([
        "device_uid",        # internal index (NOT used for mapping)
        "device_user_id",    # REAL enrollment ID (USE THIS)
        "device_user_name",
        "privilege",
        "member_id"
    ])

    for u in users:
        writer.writerow([
            u.uid,
            u.user_id,
            u.name,
            u.privilege,
            ""
        ])

conn.disconnect()

print(f"CSV exported successfully: {csv_file}")