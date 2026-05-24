# fix_me.py
from zk import ZK
from zk.user import User
from zk.finger import Finger
from config import *

zk = ZK(DEVICE_IP, port=DEVICE_PORT, timeout=DEVICE_TIMEOUT,
        password=0, force_udp=False, ommit_ping=False)

try:
    conn = zk.connect()
    conn.disable_device()

    # Get your template (uid=73, fid=6)
    templates = conn.get_templates()
    my_template = None
    for t in templates:
        if t.uid == '' and t.fid == 6:
            my_template = t
            break

    if not my_template:
        print("Template not found!")
    else:
        print(f"Found template: uid={my_template.uid} fid={my_template.fid} size={len(my_template.template)}")
        
        # Re-save with fid=0 (correct slot)
        new_finger = Finger(uid='', fid=0, valid=1, template=my_template.template)
        user_obj = User(uid='', name='', privilege=0, password='',
                       group_id='', user_id='', card=0)
        conn.save_user_template(user=user_obj, fingers=[new_finger])
        print("Fixed! Try scanning now.")

    conn.enable_device()

except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
finally:
    try:
        conn.enable_device()
        conn.disconnect()
    except:
        pass