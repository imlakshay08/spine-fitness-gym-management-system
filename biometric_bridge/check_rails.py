import requests 
r = requests.get('https://spine-fitness.com/api/access_status', params={'compcode':'SF','device_sn':'NFZ8253402448'}, timeout=30) 
users = r.json()['users'] 
[print(u) for u in users if u['device_user_id'] == '71'] 
