module Alerts
  # When the gym is actually open. Alerts about equipment are only useful while
  # somebody is there to act on them — a dead laptop at 2 AM is meant to be dead.
  class GymClock
    IST = 'Asia/Kolkata'.freeze

    # The hours the biometric is expected to be running, taken from watching
    # when it actually reports in. Sunday is mornings only: the gym does not
    # open in the evening, so an alert then would wake staff for a machine
    # nobody is standing next to.
    MORNING = [6 * 60 + 30, 11 * 60 + 30].freeze   # 6:30 – 11:30
    EVENING = [17 * 60,     21 * 60 + 30].freeze   # 5:00 – 9:30

    WEEKDAY_WINDOWS = [MORNING, EVENING].freeze
    SUNDAY_WINDOWS  = [MORNING].freeze

    def self.now
      Time.current.in_time_zone(IST)
    end

    # Everything is decided in IST, whatever zone the caller hands us — the
    # windows and the day-of-week both have to agree on which day it is.
    def self.windows(at = now)
      at.in_time_zone(IST).sunday? ? SUNDAY_WINDOWS : WEEKDAY_WINDOWS
    end

    def self.open?(at = now)
      ist     = at.in_time_zone(IST)
      minutes = (ist.hour * 60) + ist.min

      windows(ist).any? { |from, to| minutes >= from && minutes <= to }
    end

    def self.sunday?(at = now)
      at.in_time_zone(IST).sunday?
    end

    def self.window_text(at = now)
      return '6:30 AM to 11:30 AM' if sunday?(at)

      '6:30 AM to 11:30 AM and 5:00 PM to 9:30 PM'
    end
  end
end
