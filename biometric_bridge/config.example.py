# config.example.py
#
# Copy this file to config_local.py on the gym laptop and fill in the real
# values. config_local.py is gitignored and must never be committed.

DEVICE_IP      = "192.168.x.x"        # biometric device on the gym LAN
DEVICE_PORT    = 4370
DEVICE_TIMEOUT = 5
DEVICE_SN      = "DEVICE-SERIAL"      # printed on the device / conn.get_serialnumber()

RAILS_API_BASE = "https://your-app-domain"
COMP_CODE      = "SF"

# Same value as BIOMETRIC_API_TOKEN in the Rails environment.
# Generate with: ruby -rsecurerandom -e "puts SecureRandom.hex(32)"
BIOMETRIC_API_TOKEN = ""

POLL_INTERVAL_SECONDS = 20
