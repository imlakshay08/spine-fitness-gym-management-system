# Be sure to restart your server when you modify this file.

# Values matching these names are replaced with [FILTERED] in the logs.
# Beyond credentials this covers the member PII the app handles, so a log file
# (or a log shipped to a hosting dashboard) never becomes a second copy of the
# member database.
Rails.application.config.filter_parameters += [
  :password, :userPassword, :userpassword, :new_password, :old_password,
  :new_pass, :password_digest, :passd,
  :token, :secret, :api_key, :access_key, :authorization,
  :aadhaar, :mmbr_aadhaar,
  :templates, :template, :mbm_finger_template,   # fingerprint biometric data
  :cvv, :card
]
