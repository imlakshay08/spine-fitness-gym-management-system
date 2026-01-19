# Be sure to restart your server when you modify this file.

# Specify a serializer for the signed and encrypted cookie jars.
# Valid options are :json, :marshal, and :hybrid.
Ihm::Application.config.session_store :cookie_store,
  key: '_ihm_session',
  expire_after: 30.days
#Rails.Application.config.session_store :active_record_store

