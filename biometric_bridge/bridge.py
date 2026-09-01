# bridge.py
from zk import ZK
import requests
import time
import threading
from datetime import datetime, date
from config import *
from sync_access import sync_device_access

def send_to_rails(payload):
    try:
        response = requests.post(
            RAILS_API_URL,
            headers=API_HEADERS,
            json=payload,
            timeout=15
        )
        print(f"Sent: {payload} | Response: {response.status_code}")
        return response.status_code in (200, 404)
    except Exception as e:
        print("Rails API error:", e)
        return False

def sync_scheduler():
    print("Sync scheduler started — syncing every 1 minute")
    print("Running initial sync on startup...")
    sync_device_access()
    while True:
        time.sleep(60)
        print(f"Periodic sync starting at {datetime.now().strftime('%H:%M')}...")
        sync_device_access()

def heartbeat_scheduler():
    while True:
        try:
            requests.post(
                f"{RAILS_API_BASE}/api/bridge_heartbeat",
                headers=API_HEADERS,
                json={
                    "device_sn": DEVICE_SN,
                    "compcode": COMP_CODE,
                    "timestamp": datetime.now().isoformat(),
                    "bridge_version": "2.0"
                },
                timeout=10
            )
        except:
            pass  # heartbeat failure is fine — absence is noticed server-side
        time.sleep(300)  # every 5 minutes

def instant_sync_watcher():
    """Polls every 5 seconds for recent subscription renewals.
    Triggers an immediate sync if one is detected so restored
    fingers are available within seconds of renewal — not 60s."""
    last_triggered = datetime.now()
    print("Instant sync watcher started — polling every 5 seconds for renewals")
    while True:
        time.sleep(5)
        try:
            resp = requests.get(
                f"{RAILS_API_BASE}/api/sync_needed",
                headers=API_HEADERS,
                params={"compcode": COMP_CODE},
                timeout=10
            ).json()
            if resp.get("sync_needed"):
                now = datetime.now()
                # Avoid triggering more than once per 30 seconds
                if (now - last_triggered).total_seconds() > 30:
                    print(f"Subscription renewal detected — triggering immediate sync at {now.strftime('%H:%M:%S')}...")
                    sync_device_access()
                    last_triggered = now
        except:
            pass  # silent fail — 60s scheduler is the reliable fallback

def sync_device_time(conn):
    try:
        conn.set_time(datetime.now())
        print(f"Device time synced to {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    except Exception as e:
        print(f"Could not sync device time: {e}")

def main():
    require_settings()

    # Start sync scheduler in background thread
    sync_thread = threading.Thread(target=sync_scheduler, daemon=True)
    sync_thread.start()

    # Start heartbeat in background thread
    heartbeat_thread = threading.Thread(target=heartbeat_scheduler, daemon=True)
    heartbeat_thread.start()

    # Start instant sync watcher in background thread
    instant_sync_thread = threading.Thread(target=instant_sync_watcher, daemon=True)
    instant_sync_thread.start()

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

        # Sync device clock to laptop time on every startup
        sync_device_time(conn)

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
                sent = send_to_rails(payload)
                if sent:
                    last_sent.add(key)
                # if not sent (network error) — key stays out, retries next poll
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