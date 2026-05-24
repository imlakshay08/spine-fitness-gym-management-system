# bridge.py
from zk import ZK
import requests
import time
import threading
from datetime import datetime, date
from config import *
# from sync_access import sync_device_access #commentthis

SYNC_HOUR = 0  # midnight

def send_to_rails(payload):
    try:
        response = requests.post(
            RAILS_API_URL,
            json=payload,
            timeout=15
        )
        print(f"Sent: {payload} | Response: {response.status_code}")
    except Exception as e:
        print("Rails API error:", e)

def sync_scheduler():
    """Runs sync once at midnight every day"""
    print("Sync scheduler started — will sync at midnight daily")
    # Run once on startup
    print("Running initial sync on startup...")
    #sync_device_access() #commentthis

    while True:
        now = datetime.now()
        if now.hour == SYNC_HOUR and now.minute == 0:
            print(f"Midnight sync starting...")
            #sync_device_access() #commentthis
            time.sleep(61)  # prevent double trigger within same minute
        time.sleep(30)

def main():
    # Start sync scheduler in background thread
    sync_thread = threading.Thread(target=sync_scheduler, daemon=True)
    sync_thread.start()

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
        print(f"Fetching TODAY's attendance logs only ({date.today()})...")

        last_sent = set()

        while True:
            today = date.today()
            attendances = conn.get_attendance()
            device_sn = conn.get_serialnumber()

            for att in attendances:
                if att.timestamp.date() != today:
                    continue
                key = f"{att.user_id}-{att.timestamp}"
                if key in last_sent:
                    continue
                payload = {
                    "compcode": COMP_CODE,
                    "user_id": att.user_id,
                    "timestamp": att.timestamp.strftime("%Y-%m-%d %H:%M:%S"),
                    "device_sn": device_sn
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