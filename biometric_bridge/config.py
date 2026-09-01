# config.py
#
# No real values live in this file — it is committed to a public repository.
# The gym laptop keeps its actual settings in config_local.py, which sits next
# to this file and is gitignored. Copy config.example.py to config_local.py on
# the laptop and fill it in.
#
# Environment variables override config_local.py, so the same code also runs
# from a service manager or a scheduled task without a local file.

import os

try:
    import config_local as _local
except ImportError:                     # no local file — fall back to env only
    _local = None


def _setting(name, default=None, cast=str):
    """config_local.py wins over its own default; the environment wins over both."""
    value = os.environ.get(name)
    if value is None and _local is not None:
        value = getattr(_local, name, None)
    if value is None:
        value = default
    if value is None:
        return None
    return cast(value)


# --- Biometric device (local LAN) ---------------------------------------
DEVICE_IP      = _setting("DEVICE_IP")
DEVICE_PORT    = _setting("DEVICE_PORT", 4370, int)
DEVICE_TIMEOUT = _setting("DEVICE_TIMEOUT", 5, int)
DEVICE_SN      = _setting("DEVICE_SN")

# --- Rails application --------------------------------------------------
RAILS_API_BASE = (_setting("RAILS_API_BASE") or "").rstrip("/")
RAILS_API_URL  = _setting("RAILS_API_URL") or f"{RAILS_API_BASE}/api/biometric_attendances"
COMP_CODE      = _setting("COMP_CODE")

# --- Authentication to the Rails API ------------------------------------
# Must match BIOMETRIC_API_TOKEN in the Rails environment. While Rails is in
# soft-enforce mode an empty token still works, so the bridge keeps running
# until this laptop is updated.
BIOMETRIC_API_TOKEN = _setting("BIOMETRIC_API_TOKEN", "")

# Attach to every request the bridge makes to Rails.
API_HEADERS = {"Authorization": f"Bearer {BIOMETRIC_API_TOKEN}"} if BIOMETRIC_API_TOKEN else {}

POLL_INTERVAL_SECONDS = _setting("POLL_INTERVAL_SECONDS", 20, int)


def require_settings():
    """Fail loudly at startup rather than silently talking to the wrong place."""
    missing = [n for n in ("DEVICE_IP", "DEVICE_SN", "RAILS_API_BASE", "COMP_CODE")
               if not globals().get(n)]
    if missing:
        raise SystemExit(
            "Missing bridge settings: " + ", ".join(missing) +
            "\nCopy config.example.py to config_local.py and fill it in."
        )
    if not BIOMETRIC_API_TOKEN:
        print("WARNING: BIOMETRIC_API_TOKEN is not set — requests are unauthenticated. "
              "This works only while Rails is in soft-enforce mode.")
