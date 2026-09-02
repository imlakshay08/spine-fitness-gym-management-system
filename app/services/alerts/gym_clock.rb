module Alerts
  # When the gym is actually open. Alerts about equipment are only useful while
  # somebody is there to act on them — a dead laptop at 2 AM is meant to be dead.
  class GymClock
    IST = 'Asia/Kolkata'.freeze

    # The hours the biometric is expected to be running, taken from watching
    # when it actually reports in: 6:30–11:30 AM and 5:00–9:30 PM.
    WINDOWS = [[6 * 60 + 30, 11 * 60 + 30],
               [17 * 60,     21 * 60 + 30]].freeze

    def self.now
      Time.current.in_time_zone(IST)
    end

    def self.open?(at = now)
      minutes = (at.hour * 60) + at.min
      WINDOWS.any? { |from, to| minutes >= from && minutes <= to }
    end

    def self.window_text
      '6:30 AM to 11:30 AM and 5:00 PM to 9:30 PM'
    end
  end
end
