module Alerts
  # Decides whether the biometric bridge has gone quiet while the gym is open.
  #
  # The bridge posts a heartbeat every few minutes (the dashboard treats
  # anything older than 10 minutes as not-online). 20 minutes is used here so a
  # single missed beat or a slow network never wakes anybody up.
  class BiometricWatch
    STALE_AFTER = 20.minutes

    # What staff should actually do, in the order they should do it: look at
    # the dashboard first, restart only if it is red, and escalate if a restart
    # does not fix it. Sent as a template variable, so this wording can change
    # without Meta having to re-approve the template.
    RECOVERY_STEPS = [
      'Open the Spine Fitness dashboard and check the Biometric Bridge status.',
      'It should be green and say Online.',
      'If it is red, restart the laptop and make sure the biometric software starts again.',
      'If it is still red after restarting, please call Lakshay.'
    ].join(' ').freeze

    IST = 'Asia/Kolkata'.freeze

    def initialize(compcode: 'SF')
      @compcode = compcode
    end

    # Returns an alert hash, or nil when there is nothing to say.
    def call
      return nil unless GymClock.open?

      beat = TrnBridgeHeartbeat.where(bh_compcode: @compcode).order(bh_last_seen: :desc).first

      if beat.nil?
        return alert('Biometric entry system',
                     'No signal has ever been received from the entry machine.',
                     RECOVERY_STEPS)
      end

      last_seen = beat.bh_last_seen
      return nil if last_seen > STALE_AFTER.ago

      alert('Biometric entry system',
            "No signal since #{last_seen.in_time_zone(IST).strftime('%l:%M %p').strip}, " \
            "about #{ago_in_words(last_seen)} ago. Members cannot enter using fingerprint.",
            RECOVERY_STEPS)
    end

    private

    def alert(service, status, action)
      { kind: 'BIO', service: service, status: status, action: action }
    end

    def ago_in_words(time)
      minutes = ((Time.current - time) / 60).round
      return "#{minutes} minutes" if minutes < 90

      hours = (minutes / 60.0).round
      hours < 24 ? "#{hours} hours" : "#{(hours / 24.0).round} days"
    end
  end
end
