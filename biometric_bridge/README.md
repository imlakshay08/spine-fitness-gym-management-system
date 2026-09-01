# Biometric bridge — gym laptop setup

The scripts here run on the gym's Windows laptop. They talk to the ZKTeco
device over the local network and to the Rails app over HTTPS.

## No real values live in this folder

Device IP, device serial, the Rails URL and the API token used to be written
directly into these files, which put the gym's hardware details in a public
repository. They now come from `config_local.py`, which is gitignored.

## First-time setup on the laptop

```bash
cd biometric_bridge
pip install -r requirements.txt
copy config.example.py config_local.py     # then edit it
```

Fill in `config_local.py`:

| Setting | Value |
|---|---|
| `DEVICE_IP` | the biometric device's address on the gym LAN |
| `DEVICE_SN` | the device serial (`conn.get_serialnumber()`) |
| `RAILS_API_BASE` | `https://spine-fitness.com` |
| `COMP_CODE` | `SF` |
| `BIOMETRIC_API_TOKEN` | the same value as `BIOMETRIC_API_TOKEN` in Railway |

Every setting can also come from an environment variable of the same name,
which takes precedence — useful if the bridge is ever run from a service
manager or a scheduled task instead of the startup shortcut.

## Checking it works

```bash
python check_rails.py     # can we reach Rails, and is the token accepted?
python test_access.py     # can we reach the device, and who is enrolled?
python bridge.py          # the real thing
```

`bridge.py` refuses to start with settings missing, and prints a warning if
`BIOMETRIC_API_TOKEN` is blank — that only works while Rails is still in
soft-enforce mode.

## The token

Every request to Rails now sends `Authorization: Bearer <BIOMETRIC_API_TOKEN>`.

Rails accepts unauthenticated requests until `BIOMETRIC_AUTH_ENFORCE=true` is
set there, so the order is: update this laptop first, confirm a real fingerprint
punch is recorded, *then* turn on enforcement. See `../SECURITY_FIXES.md`.
