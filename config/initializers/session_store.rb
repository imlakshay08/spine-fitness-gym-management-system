# Be sure to restart your server when you modify this file.

Ihm::Application.config.session_store :cookie_store,
  key:          '_ihm_session',
  expire_after: 30.days,

  # JavaScript cannot read the cookie, so an XSS cannot lift a live session.
  httponly:     true,

  # Never send the session over plain http.
  #
  # This is the one attribute here that can lock staff out, so it has a switch.
  # A browser REJECTS a Secure cookie that arrives over http — so if anyone can
  # still reach the app on http://, they would log in and bounce straight back
  # to the login screen.
  #
  # Verified safe here: `curl -I http://spine-fitness.com/login` returns a 301
  # to https from Railway's edge, so plain http never reaches this app and no
  # browser is ever handed a Secure cookie over an insecure connection.
  #
  # The switch stays because that redirect is infrastructure, not code, and
  # could change without this file changing. If logins ever start bouncing
  # back to the login screen, SECURE_COOKIES=false is an instant fix with no
  # redeploy.
  secure:       Rails.env.production? &&
                  ENV.fetch('SECURE_COOKIES', 'true').to_s.downcase != 'false',

  # The cookie is withheld from cross-site POSTs, which blocks the common
  # form-autosubmit CSRF entirely — before the token check even runs. :lax
  # (not :strict) so following a link into the app keeps you logged in.
  same_site:    :lax

# Only the cookie *attributes* changed, not the signing key, so sessions that
# are already open stay valid — nobody gets logged out by this.
