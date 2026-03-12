# bridge.py

from zk import ZK
import requests
import time
from datetime import datetime
from config import *

def send_to_rails(payload):
    try:
        response = requests.post(
            RAILS_API_URL,
            json=payload,
            timeout=5
        )
        print(f"Sent: {payload} | Response: {response.status_code}")
    except Exception as e:
        print("Rails API error:", e)

def main():
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

        print("Connected to device")
        print("Fetching attendance logs...")

        last_sent = set()

        while True:
            attendances = conn.get_attendance()

            for att in attendances:
                key = f"{att.user_id}-{att.timestamp}"

                # Prevent duplicate sending
                if key in last_sent:
                    continue

                payload = {
                    "compcode": COMP_CODE,
                    "user_id": att.user_id,
                    "timestamp": att.timestamp.strftime("%Y-%m-%d %H:%M:%S"),
                    "device_sn": conn.serial_number
                }

                send_to_rails(payload)
                last_sent.add(key)

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
