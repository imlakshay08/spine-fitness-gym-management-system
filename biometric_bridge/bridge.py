from zk import ZK
import requests
import time
import os
from config import *

LAST_SENT_FILE = "last_sent_keys.txt"

def load_last_sent():
    if os.path.exists(LAST_SENT_FILE):
        with open(LAST_SENT_FILE, 'r') as f:
            return set(line.strip() for line in f if line.strip())
    return set()

def save_key(key):
    with open(LAST_SENT_FILE, 'a') as f:
        f.write(key + '\n')

def send_to_rails(payload):
    try:
        response = requests.post(
            RAILS_API_URL,
            json=payload,
            timeout=5
        )
        print(f"Sent: {payload} | Response: {response.status_code}")
        return response.status_code
    except Exception as e:
        print("Rails API error:", e)
        return None

def main():
    last_sent = load_last_sent()
    print(f"Loaded {len(last_sent)} previously sent keys")

    zk = ZK(
        DEVICE_IP,
        port=DEVICE_PORT,
        timeout=DEVICE_TIMEOUT,
        password=0,
        force_udp=False,
        ommit_ping=False
    )

    print("Connecting to biometric device...")

    try:
        conn = zk.connect()
        conn.disable_device()
        device_sn = conn.get_serialnumber()
        print(f"Connected. Serial: {device_sn}")

        while True:
            attendances = conn.get_attendance()

            for att in attendances:
                key = f"{att.user_id}-{att.timestamp}"

                if key in last_sent:
                    continue

                payload = {
                    "compcode": COMP_CODE,
                    "user_id":  str(att.user_id),
                    "timestamp": att.timestamp.strftime("%Y-%m-%d %H:%M:%S"),
                    "device_sn": device_sn
                }

                status_code = send_to_rails(payload)

                # Only mark as sent if Rails accepted it
                if status_code in [200, 404]:
                    last_sent.add(key)
                    save_key(key)

            time.sleep(POLL_INTERVAL_SECONDS)

    except Exception as e:
        print("Device connection error:", e)
    finally:
        try:
            conn.enable_device()
            conn.disconnect()
        except:
            pass

if __name__ == "__main__":
    main()