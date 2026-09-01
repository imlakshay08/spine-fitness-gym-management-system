module Alerts
  # Decides whether the biometric bridge has gone quiet while the gym is open.
  #
  # The bridge posts a heartbeat every few minutes (the dashboard treats
  # anything older than 10 minutes as not-online). 20 minutes is used here so a
  # single missed beat or a slow network never wakes anybody up.
  class BiometricWatch
    STALE_AFTER = 20.minutes
    IST         = 'Asia/Kolkata'.freeze

    def initialize(compcode: 'SF')
      @compcode = compcode
    end

    # Returns an alert hash, or nil when there is nothing to say.
    def call
      return nil unless GymClock.open?

      beat = TrnBridgeHeartbeat.where(bh_compcode: @compcode).order(bh_last_seen: :desc).first

      if beat.nil?
        return alert('The biometric machine has never connected',
                     'The software has not received any signal from the machine.',
                     'Please check the laptop is on, and that the biometric software is running.')
      end

      last_seen = beat.bh_last_seen
      return nil if last_seen > STALE_AFTER.ago

      alert('The biometric machine is not connected',
            "No signal since #{last_seen.in_time_zone(IST).strftime('%l:%M %p').strip}, " \
            "about #{ago_in_words(last_seen)} ago. Members cannot be let in by fingerprint.",
            'Please restart the laptop, then check the biometric software has started again.')
    end

    private

    def alert(headline, details, action)
      { kind: 'BIO', headline: headline, details: details, action: action }
    end

    def ago_in_words(time)
      minutes = ((Time.current - time) / 60).round
      return "#{minutes} minutes" if minutes < 90

      hours = (minutes / 60.0).round
      hours < 24 ? "#{hours} hours" : "#{(hours / 24.0).round} days"
    end
  end
end
