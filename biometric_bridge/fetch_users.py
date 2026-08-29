import csv
from zk import ZK
from config import *

zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=5,
        password=0, force_udp=False, ommit_ping=False)
conn = zk.connect()
users = conn.get_users()

csv_file = "biometric_users.csv"
with open(csv_file, mode="w", newline="", encoding="utf-8") as file:
    writer = csv.writer(file)
    writer.writerow([
        "device_uid",
        "device_user_id",
        "device_user_name",
        "privilege",
        "keep"          # ← fill 'yes' here for people to preserve
    ])
    for u in users:
        keep_default = "yes" if u.privilege == 14 else ""  # admins pre-marked
        writer.writerow([u.uid, u.user_id, u.name, u.privilege, keep_default])

conn.disconnect()
print(f"CSV exported: {csv_file}")
print("Open the CSV, mark 'yes' in the 'keep' column for important people, save, then run cleanup_selective.py")