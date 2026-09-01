# Staged CSRF protection for the HTML controllers.
#
# Every one of these controllers used to carry
#   skip_before_action :verify_authenticity_token
# because the UI posts through $.ajax with FormData rather than through
# submitted forms, and those requests carried no authenticity token. With CSRF
# off, a page on any other site could silently post to /member_list/ajax_process
# using a logged-in admin's cookie and create or delete records.
#
# public/assets/js/csrf.js now adds the token to every same-origin $.ajax call,
# so the token should be present everywhere. "Should" is not good enough to
# switch on hard failures under a gym that is open and working, so:
#
#   Now                      CSRF_ENFORCE unset
#                            -> unverified writes are ALLOWED and logged as
#                               "[CSRF] UNVERIFIED", naming the exact path.
#
#   After a few days of clean logs
#                            CSRF_ENFORCE=true
#                            -> unverified writes are rejected.
#
# Check the logs before flipping it. Any path that shows up is a form or an
# AJAX call that needs the token added; fix that first. Flipping back is an
# env var change, not a deploy.
module SoftCsrfProtection
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token, raise: false
    before_action :verify_authenticity_token_softly
  end

  private

  def verify_authenticity_token_softly
    return true if request.get? || request.head?
    return true if verified_request?

    if ENV['CSRF_ENFORCE'].to_s.downcase == 'true'
      Rails.logger.warn "[CSRF] REJECTED #{request.method} #{request.path} from #{request.remote_ip}"
      raise ActionController::InvalidAuthenticityToken
    else
      Rails.logger.warn "[CSRF] UNVERIFIED #{request.method} #{request.path} " \
                        "from #{request.remote_ip} (allowed — soft mode; " \
                        "set CSRF_ENFORCE=true to reject)"
      true
    end
  end
end
