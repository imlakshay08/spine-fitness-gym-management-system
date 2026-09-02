module Alerts
  # Decides whether the biometric bridge has gone quiet while the gym is open.
  #
  # The bridge posts a heartbeat every few minutes (the dashboard treats
  # anything older than 10 minutes as not-online). 20 minutes is used here so a
  # single missed beat or a slow network never wakes anybody up.
  class BiometricWatch
    STALE_AFTER = 20.minutes

    # The name staff actually use for the machine, not an internal one.
    SERVICE = 'Fingerprint Biometric Device'.freeze

    # What an outage means on the floor. Kept concrete — staff need to know
    # members are being blocked at the door AND that attendance is being lost,
    # because the second part is invisible until somebody checks a report.
    IMPACT = 'Members are not able to enter the gym with their fingerprint, ' \
             'and their attendance is not being recorded.'.freeze

    # What to do, in the order to do it, naming the exact screen and the exact
    # thing to look for. Every step says where to look, what it should say, and
    # what to do when it does not.
    #
    # Written differently for who is reading it. Staff are standing in the gym,
    # so they are told to fix it. The owner is not, so hers opens with who to
    # call and then describes the same fix in the third person — she can read
    # it straight down the phone to them. %{staff} is filled in from the Staff
    # List when the message is sent, so it stays correct if a trainer changes.
    #
    # Sent as a template variable, so this wording can be changed freely — Meta
    # only re-approves the fixed text around {{1}}..{{4}}, never the values.
    RECOVERY_STEPS = {
      staff: [
        'Open the spine-fitness.com dashboard and check the Biometric Bridge status.',
        'It should be green and say Online.',
        'If it is red, restart the laptop and make sure the biometric bridge starts again ' \
        'and shows green and Online on the dashboard.',
        'If it is still red after restarting the laptop, please call Lakshay.'
      ].join(' ').freeze,

      owner: [
        'Call %{staff} at the gym and ask them to restart the laptop.',
        'They should open the spine-fitness.com dashboard and check the Biometric Bridge status.',
        'It should be green and say Online.',
        'If it is red, they should restart the laptop and make sure the biometric bridge ' \
        'starts again and shows green and Online on the dashboard.',
        'If it is still red after restarting the laptop, please call Lakshay.'
      ].join(' ').freeze
    }.freeze

    IST = 'Asia/Kolkata'.freeze

    def initialize(compcode: 'SF')
      @compcode = compcode
    end

    # Returns an alert hash, or nil when there is nothing to say.
    def call
      return nil unless GymClock.open?

      beat = TrnBridgeHeartbeat.where(bh_compcode: @compcode).order(bh_last_seen: :desc).first

      if beat.nil?
        return alert(SERVICE,
                     "No signal has ever been received from the fingerprint machine. #{IMPACT}")
      end

      last_seen = beat.bh_last_seen
      return nil if last_seen > STALE_AFTER.ago

      alert(SERVICE,
            "No signal since #{last_seen.in_time_zone(IST).strftime('%l:%M %p').strip}, " \
            "about #{ago_in_words(last_seen)} ago. #{IMPACT}")
    end

    private

    # :action carries both wordings; the sender picks the one for whoever it is
    # writing to, so one outage produces one set of facts and two sets of
    # instructions.
    def alert(service, status)
      { kind: 'BIO', service: service, status: status, action: RECOVERY_STEPS }
    end

    def ago_in_words(time)
      minutes = ((Time.current - time) / 60).round
      return "#{minutes} minutes" if minutes < 90

      hours = (minutes / 60.0).round
      hours < 24 ? "#{hours} hours" : "#{(hours / 24.0).round} days"
    end
  end
end
