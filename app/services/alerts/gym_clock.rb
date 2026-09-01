module Alerts
  # When the gym is actually open. Alerts about equipment are only useful while
  # somebody is there to act on them — a dead laptop at 2 AM is meant to be dead.
  class GymClock
    IST = 'Asia/Kolkata'.freeze

    # 5:30 AM – 12:30 PM and 4:30 PM – 10:30 PM
    WINDOWS = [[5 * 60 + 30, 12 * 60 + 30],
               [16 * 60 + 30, 22 * 60 + 30]].freeze

    def self.now
      Time.current.in_time_zone(IST)
    end

    def self.open?(at = now)
      minutes = (at.hour * 60) + at.min
      WINDOWS.any? { |from, to| minutes >= from && minutes <= to }
    end

    def self.window_text
      '5:30 AM to 12:30 PM and 4:30 PM to 10:30 PM'
    end
  end
end
