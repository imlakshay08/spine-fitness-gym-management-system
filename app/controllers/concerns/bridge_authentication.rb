# Shared bearer-token authentication for the endpoints the gym laptop's Python
# bridge talks to.
#
# These endpoints write attendance, hand out device user ids and store
# fingerprint templates, so they must not stay open to the internet. But the
# bridge runs on a laptop inside the gym that can only be updated in person,
# and attendance must not stop in the meantime.
#
# So this rolls out in two stages, controlled entirely by environment
# variables — no redeploy needed to switch:
#
#   Stage 1 (now)   BIOMETRIC_API_TOKEN set, BIOMETRIC_AUTH_ENFORCE unset
#                   -> requests without a valid token are ALLOWED but logged
#                      with their IP, so you can see exactly who is calling.
#
#   Stage 2 (after the laptop has the token in config_local.py)
#                   BIOMETRIC_AUTH_ENFORCE=true
#                   -> requests without a valid token get 401.
#
# Check the logs for "[BridgeAuth]" before flipping stage 2: the only
# unauthenticated caller should be the gym bridge itself.
module BridgeAuthentication
  extend ActiveSupport::Concern

  # Soft-mode log throttling. Shared across every controller that includes this
  # concern, and per Puma process — which is fine, since the point is only to
  # keep the log readable enough to spot an unexpected caller.
  QUIET_FOR  = 15.minutes
  SEEN_LIMIT = 500                       # so a caller rotating IPs cannot grow this forever
  SEEN       = {}
  SEEN_LOCK  = Mutex.new

  included do
    before_action :authenticate_bridge!
  end

  private

  def authenticate_bridge!
    expected = ENV["BIOMETRIC_API_TOKEN"].to_s

    # Nothing configured yet — behave exactly as before.
    if expected.empty?
      Rails.logger.warn "[BridgeAuth] BIOMETRIC_API_TOKEN is not set; #{request.path} is unauthenticated"
      return true
    end

    return true if valid_bridge_token?(expected)

    if enforce_bridge_auth?
      Rails.logger.warn "[BridgeAuth] REJECTED #{request.path} from #{request.remote_ip}"
      head :unauthorized
      false
    else
      log_soft_mode
      true
    end
  end

  # The bridge polls /api/sync_needed every 7 seconds, so logging every
  # unauthenticated call buries the one thing stage 1 exists to reveal: a
  # caller that is NOT the gym laptop. Each path+IP pair is logged the first
  # time it is seen and then at most once every QUIET_FOR, carrying a count of
  # the calls suppressed in between so nothing is silently dropped.
  def log_soft_mode
    key       = "#{request.path}|#{request.remote_ip}"
    should_log = false
    suppressed = 0

    SEEN_LOCK.synchronize do
      SEEN.clear if SEEN.size > SEEN_LIMIT
      entry = SEEN[key]

      if entry.nil? || entry[:at] < QUIET_FOR.ago
        should_log = true
        suppressed = entry ? entry[:count] : 0
        SEEN[key]  = { at: Time.current, count: 0 }
      else
        entry[:count] += 1
      end
    end

    return unless should_log

    tail = suppressed.positive? ? " [#{suppressed} more since the last line]" : ""
    Rails.logger.warn "[BridgeAuth] UNAUTHENTICATED #{request.path} from #{request.remote_ip} " \
                      "(allowed — soft mode; set BIOMETRIC_AUTH_ENFORCE=true to reject)#{tail}"
  end

  def valid_bridge_token?(expected)
    given = request.headers["Authorization"].to_s.split(" ").last.to_s
    return false if given.empty?

    # Length-independent, constant-time: secure_compare raises on length
    # mismatch, which would itself leak the expected length.
    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(given),
      ::Digest::SHA256.hexdigest(expected)
    )
  end

  def enforce_bridge_auth?
    ENV["BIOMETRIC_AUTH_ENFORCE"].to_s.downcase == "true"
  end
end
