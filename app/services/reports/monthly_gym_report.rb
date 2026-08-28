module Reports
  # A month in review: what the gym earned, who joined, who left, and what next
  # month already looks like.
  class MonthlyGymReport < GymReportBase
    def initialize(month: nil, compcode: 'SF')
      first = (month || Time.current.in_time_zone(IST).to_date.prev_month).beginning_of_month
      # Measured as at the last day of the month being reported.
      super(compcode: compcode, as_of: first.end_of_month)
      @first = first
      @last  = first.end_of_month
    end

    attr_reader :first, :last

    def call
      {
        kind:         :monthly,
        title:        'MONTHLY REPORT',
        period:       first.strftime('%B %Y'),
        generated_at: in_ist(Time.current),
        kpis:         kpis,
        money:        money_section,
        plans:        plan_mix,
        growth:       growth_section,
        footfall:     footfall_section,
        regulars:     top_regulars,
        outlook:      outlook_section
      }
    end

    private

    def month_range
      @month_range ||= ist_range(first, last)
    end

    def prev_month_range
      @prev_month_range ||= ist_range(first.prev_month, first.prev_month.end_of_month)
    end

    def payments
      @payments ||= payments_between(month_range).to_a
    end

    def collected
      @collected ||= payments.sum { |p| p.pay_amount.to_f }
    end

    def subscriptions
      @subscriptions ||= subscriptions_between(month_range).to_a
    end

    def kpis
      prev = payments_between(prev_month_range).sum { |p| p.pay_amount.to_f }
      change = pct_change(collected, prev)
      [
        { label: 'Money received',      value: money(collected),
          note: change ? "#{change.abs}% #{change.positive? ? 'more' : 'less'} than #{first.prev_month.strftime('%B')}" : "nothing last #{first.prev_month.strftime('%B')}" },
        { label: 'Memberships taken',   value: subscriptions.size.to_s,
          note: "#{new_joiners.size} new, #{renewals.size} renewed" },
        { label: 'Members came',        value: total_visits.to_s,
          note: "#{unique_visitors} different members" },
        { label: 'Running memberships', value: active_member_ids.size.to_s,
          note: "#{expiring_next_month.size} finish next month" }
      ]
    end

    # ── money ───────────────────────────────────────────────────────────────

    def money_section
      prev = payments_between(prev_month_range).sum { |p| p.pay_amount.to_f }
      by_mode = payments.group_by { |p| p.pay_mode.presence || 'unspecified' }
                        .map { |mode, rows| { mode: mode.to_s.upcase, amount: rows.sum { |r| r.pay_amount.to_f },
                                              amount_text: money(rows.sum { |r| r.pay_amount.to_f }), count: rows.size } }
                        .sort_by { |m| -m[:amount] }

      busiest = payments.group_by { |p| in_ist(p.created_at).to_date }
                        .max_by { |_d, rows| rows.sum { |r| r.pay_amount.to_f } }

      {
        total:       collected,
        total_text:  money(collected),
        count:       payments.size,
        average:     money(payments.any? ? collected / payments.size : 0),
        by_mode:     by_mode,
        previous:    money(prev),
        change_pct:  pct_change(collected, prev),
        best_day:    busiest && busiest[0],
        best_day_amount: busiest && money(busiest[1].sum { |r| r.pay_amount.to_f })
      }
    end

    # ── what sold ───────────────────────────────────────────────────────────

    def plan_mix
      subscriptions.group_by { |s| s.ms_plan_id.to_s }
                   .map do |plan_id, rows|
                     plan = plans_by_id[plan_id]
                     revenue = rows.sum { |r| r.ms_amount_paid.to_f }
                     { plan: plan&.plan_name.presence || "Plan ##{plan_id}",
                       count: rows.size, revenue: revenue, revenue_text: money(revenue),
                       share: collected.zero? ? 0 : ((revenue / collected) * 100).round }
                   end
                   .sort_by { |r| -r[:revenue] }
    end

    # ── growth / churn ──────────────────────────────────────────────────────

    def first_subscription_ids
      @first_subscription_ids ||= TrnMemberSubscription
                                    .where(ms_compcode: compcode)
                                    .group(:ms_member_id)
                                    .minimum(:id)
                                    .values
                                    .to_set
    end

    def new_joiners
      @new_joiners ||= subscriptions.select { |s| first_subscription_ids.include?(s.id) }
    end

    def renewals
      @renewals ||= subscriptions.reject { |s| first_subscription_ids.include?(s.id) }
    end

    # Anyone whose membership ran out during the month, split by whether they
    # came back. This is the number that tells the owner if the gym is leaking.
    def expired_in_month
      @expired_in_month ||= latest_end_dates_at_month_end
    end

    def latest_end_dates_at_month_end
      ended = TrnMemberSubscription.where(ms_compcode: compcode)
                                   .where(ms_end_date: first..last)
                                   .pluck(:ms_member_id).uniq

      ended.map do |mid|
        latest = latest_end_dates[mid.to_s]
        { member_id: mid, name: member_name(mid), phone: member_phone(mid),
          renewed: latest.present? && latest > last }
      end
    end

    def growth_section
      lost = expired_in_month.reject { |m| m[:renewed] }
      kept = expired_in_month.select { |m| m[:renewed] }
      rate = expired_in_month.any? ? ((kept.size.to_f / expired_in_month.size) * 100).round : nil

      {
        new_members:    new_joiners.size,
        new_revenue:    money(new_joiners.sum { |s| s.ms_amount_paid.to_f }),
        renewals:       renewals.size,
        renewal_revenue: money(renewals.sum { |s| s.ms_amount_paid.to_f }),
        due_to_expire:  expired_in_month.size,
        retained:       kept.size,
        lost:           lost.size,
        retention_pct:  rate,
        lost_members:   lost.select { |m| contactable?(m[:member_id]) }.first(12)
      }
    end

    # ── footfall ────────────────────────────────────────────────────────────

    def allowed_punches
      @allowed_punches ||= attendance_between(month_range, status: 'ALLOWED').to_a
    end

    def denied_punches
      @denied_punches ||= attendance_between(month_range, status: 'DENIED').to_a
    end

    def total_visits
      allowed_punches.size
    end

    def unique_visitors
      allowed_punches.map(&:att_member_id).uniq.size
    end

    def avg_per_day
      days = [(last - first).to_i + 1, 1].max
      (total_visits.to_f / days).round(1)
    end

    def footfall_section
      by_day  = allowed_punches.group_by { |p| in_ist(p.att_punch_time).to_date }
      by_hour = allowed_punches.group_by { |p| in_ist(p.att_punch_time).hour }
      by_wday = allowed_punches.group_by { |p| in_ist(p.att_punch_time).strftime('%A') }

      busiest_day  = by_day.max_by { |_d, rows| rows.size }
      busiest_hour = by_hour.max_by { |_h, rows| rows.size }
      busiest_wday = by_wday.max_by { |_w, rows| rows.size }

      {
        visits:        total_visits,
        unique:        unique_visitors,
        avg_per_day:   avg_per_day,
        busiest_day:   busiest_day && busiest_day[0],
        busiest_day_count: busiest_day && busiest_day[1].size,
        busiest_hour:  busiest_hour && hour_label(busiest_hour[0]),
        busiest_weekday: busiest_wday && busiest_wday[0],
        denied:        denied_punches.size,
        denied_members: denied_punches.map(&:att_member_id).uniq.size
      }
    end

    def hour_label(hour)
      "#{clock(hour)}-#{clock((hour + 1) % 24)}"
    end

    def clock(hour)
      display = hour % 12
      display = 12 if display.zero?
      "#{display} #{hour < 12 ? 'AM' : 'PM'}"
    end

    # Recognising the regulars is the cheapest retention tool a gym has.
    def top_regulars
      allowed_punches.group_by(&:att_member_id)
                     .select { |mid, _rows| contactable?(mid) }
                     .map { |mid, rows| { name: member_name(mid), phone: member_phone(mid), visits: rows.size } }
                     .sort_by { |r| -r[:visits] }
                     .first(8)
    end

    # ── what next month looks like ──────────────────────────────────────────

    def expiring_next_month
      @expiring_next_month ||= begin
        from = last + 1
        to   = from.end_of_month
        latest_end_dates
          .select { |mid, end_on| end_on && end_on >= from && end_on <= to && on_roll?(mid) }
          .sort_by { |_mid, end_on| end_on }
          .map { |mid, end_on| { member_id: mid, name: member_name(mid), phone: member_phone(mid), end_date: end_on } }
      end
    end

    def outlook_section
      # What those expiring memberships were last worth — revenue at risk.
      at_risk = expiring_next_month.sum do |row|
        sub = TrnMemberSubscription.where(ms_compcode: compcode, ms_member_id: row[:member_id].to_s)
                                   .order(ms_end_date: :desc).first
        sub&.ms_amount_paid.to_f
      end

      {
        expiring:      expiring_next_month,
        expiring_count: expiring_next_month.size,
        at_risk:       money(at_risk),
        lapsed_45:     lapsed_within(45).size,
        active:        active_member_ids.size
      }
    end
  end
end
