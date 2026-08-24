module Reports
  # Shared plumbing for the owner reports.
  #
  # Two data quirks this codebase has, handled once here so both reports agree:
  #
  #   1. Timestamps are stored UTC while the gym runs on IST, so an "IST day"
  #      is a UTC range, not a DATE() comparison.
  #   2. trn_payments.pay_date is copied from the subscription's START date, not
  #      the moment money was taken (409 of 426 rows differ, 10 are future
  #      dated). Money "collected on a day" therefore keys off created_at.
  class GymReportBase
    IST = 'Asia/Kolkata'.freeze

    def initialize(compcode: 'SF', as_of: nil)
      @compcode = compcode
      @as_of    = as_of
    end

    private

    attr_reader :compcode

    def tz
      @tz ||= ActiveSupport::TimeZone[IST]
    end

    # Every "expiring / lapsed / active" figure is measured from the date the
    # report covers, not from the clock — otherwise a report re-run for an
    # earlier day would quote today's call list.
    def today
      @today ||= @as_of || Time.current.in_time_zone(IST).to_date
    end

    # UTC range covering one IST calendar day.
    def ist_day_range(date)
      start = tz.local(date.year, date.month, date.day).utc
      start...(start + 1.day)
    end

    def ist_range(from_date, to_date)
      start  = tz.local(from_date.year, from_date.month, from_date.day).utc
      finish = tz.local(to_date.year, to_date.month, to_date.day).utc + 1.day
      start...finish
    end

    def in_ist(time)
      time && time.in_time_zone(IST)
    end

    # ── shared queries ──────────────────────────────────────────────────────

    def payments_between(range)
      TrnPayment.where(pay_compcode: compcode, created_at: range)
    end

    def subscriptions_between(range)
      TrnMemberSubscription.where(ms_compcode: compcode, created_at: range)
    end

    def attendance_between(range, status: nil)
      scope = TrnMemberAttendance.where(att_compcode: compcode, att_punch_time: range)
      scope = scope.where(att_status: status) if status
      scope
    end

    def members_by_id
      @members_by_id ||= MstMembersList.where(mmbr_compcode: compcode).index_by { |m| m.id.to_s }
    end

    def plans_by_id
      @plans_by_id ||= MstMembershipPlan.where(plan_compcode: compcode).index_by { |p| p.id.to_s }
    end

    def member_name(member_id)
      members_by_id[member_id.to_s]&.mmbr_name.presence || '(deleted member)'
    end

    # Rows left behind by the hard deletes that predate the soft-delete flag.
    # They still count in totals, but they cannot be phoned, so they never
    # belong on an action list.
    def contactable?(member_id)
      m = members_by_id[member_id.to_s]
      m.present? && m.mmbr_contact.present?
    end

    def member_phone(member_id)
      members_by_id[member_id.to_s]&.mmbr_contact.to_s
    end

    def on_roll?(member_id)
      m = members_by_id[member_id.to_s]
      m.present? && m.on_roll?
    end

    # Latest subscription end date per member — the basis for active / expiring
    # / lapsed. Computed once, in one query.
    def latest_end_dates
      @latest_end_dates ||= TrnMemberSubscription
                              .where(ms_compcode: compcode)
                              .group(:ms_member_id)
                              .maximum(:ms_end_date)
    end

    def active_member_ids
      @active_member_ids ||= latest_end_dates.select { |mid, end_on| end_on && end_on >= today && on_roll?(mid) }.keys
    end

    # Members whose membership runs out within the window — the call list.
    def expiring_within(days)
      cutoff = today + days
      latest_end_dates
        .select { |mid, end_on| end_on && end_on >= today && end_on <= cutoff && on_roll?(mid) }
        .sort_by { |_mid, end_on| end_on }
        .map do |mid, end_on|
          { member_id: mid, name: member_name(mid), phone: member_phone(mid),
            end_date: end_on, days_left: (end_on - today).to_i }
        end
    end

    # Expired recently and never renewed — recoverable revenue, unlike a
    # cumulative "expired ever" count that only ever grows.
    def lapsed_within(days)
      floor = today - days
      latest_end_dates
        .select { |mid, end_on| end_on && end_on < today && end_on >= floor && on_roll?(mid) }
        .sort_by { |_mid, end_on| -end_on.to_time.to_i }
        .map do |mid, end_on|
          { member_id: mid, name: member_name(mid), phone: member_phone(mid),
            end_date: end_on, days_ago: (today - end_on).to_i }
        end
    end

    def money(value)
      number = value.to_f
      text   = (number % 1).zero? ? format('%d', number) : format('%.2f', number)
      "Rs. #{ActiveSupport::NumberHelper.number_to_delimited(text, delimiter: ',')}"
    end

    def pct_change(current, previous)
      return nil if previous.to_f.zero?
      (((current.to_f - previous.to_f) / previous.to_f) * 100).round
    end
  end
end
