import requests
from config import *

r = requests.get(
    f"{RAILS_API_BASE}/api/access_status",
    params={"compcode": COMP_CODE, "device_sn": DEVICE_SN},
    headers=API_HEADERS,
    timeout=30,
)
print(r.status_code)
print(r.text[:2000])
