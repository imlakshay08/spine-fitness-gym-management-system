import requests 
r = requests.get('', params={'compcode':'','device_sn':''}, timeout=30) 
users = r.json()['users'] 
[print(u) for u in users if u['device_user_id'] == ''] 
