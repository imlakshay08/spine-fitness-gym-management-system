module Reports
  # One day of gym activity, as the owner would want to read it: what came in,
  # who joined, who trained, and who needs a phone call tomorrow.
  class DailyGymReport < GymReportBase
    def initialize(date: nil, compcode: 'SF')
      resolved = date || Time.current.in_time_zone(IST).to_date
      super(compcode: compcode, as_of: resolved)
      @date = resolved
    end

    attr_reader :date

    def call
      {
        kind:        :daily,
        title:       'DAILY REPORT',
        period:      date.strftime('%A, %d %b %Y'),
        generated_at: in_ist(Time.current),
        kpis:        kpis,
        money:       money_section,
        sales:       sales_section,
        footfall:    footfall_section,
        turned_away: turned_away_section,
        attention:   attention_section,
        membership:  membership_section
      }
    end

    private

    def day_range
      @day_range ||= ist_day_range(date)
    end

    def prev_day_range
      @prev_day_range ||= ist_day_range(date - 1)
    end

    def todays_payments
      @todays_payments ||= payments_between(day_range).to_a
    end

    def collected
      @collected ||= todays_payments.sum { |p| p.pay_amount.to_f }
    end

    def kpis
      [
        { label: 'Collected today', value: money(collected),                  note: "#{todays_payments.size} payment#{'s' if todays_payments.size != 1}" },
        { label: 'New subscriptions', value: todays_subscriptions.size.to_s,  note: sales_split_note },
        { label: 'Member visits',   value: footfall[:unique].to_s,            note: utilisation_note },
        { label: 'Turned away',     value: denied_members.size.to_s,          note: denied_members.any? ? 'expired — call them' : 'none' }
      ]
    end

    # ── money ───────────────────────────────────────────────────────────────

    def money_section
      by_mode = todays_payments.group_by { |p| p.pay_mode.presence || 'unspecified' }
                               .map { |mode, rows| [mode.to_s.upcase, rows.sum { |r| r.pay_amount.to_f }, rows.size] }
                               .sort_by { |_m, amount, _n| -amount }

      yesterday = payments_between(prev_day_range).sum { |p| p.pay_amount.to_f }
      mtd       = payments_between(ist_range(date.beginning_of_month, date)).sum { |p| p.pay_amount.to_f }

      {
        total:      collected,
        total_text: money(collected),
        count:      todays_payments.size,
        by_mode:    by_mode.map { |mode, amount, n| { mode: mode, amount: amount, amount_text: money(amount), count: n } },
        yesterday:  money(yesterday),
        change_pct: pct_change(collected, yesterday),
        mtd:        money(mtd)
      }
    end

    # ── sales ───────────────────────────────────────────────────────────────

    def todays_subscriptions
      @todays_subscriptions ||= subscriptions_between(day_range).order(:id).to_a
    end

    # A member's very first subscription means a new joiner; anything else is
    # a renewal. Counted from the whole history, not just today.
    def first_subscription_ids
      @first_subscription_ids ||= TrnMemberSubscription
                                    .where(ms_compcode: compcode)
                                    .group(:ms_member_id)
                                    .minimum(:id)
                                    .values
                                    .to_set
    end

    def sales_section
      todays_subscriptions.map do |sub|
        plan = plans_by_id[sub.ms_plan_id.to_s]
        {
          member:   member_name(sub.ms_member_id),
          phone:    member_phone(sub.ms_member_id),
          plan:     plan&.plan_name.presence || "Plan ##{sub.ms_plan_id}",
          amount:   sub.ms_amount_paid.to_f,
          amount_text: money(sub.ms_amount_paid),
          mode:     (sub.ms_payment_mode.presence || '—').to_s.upcase,
          valid_to: sub.ms_end_date,
          type:     first_subscription_ids.include?(sub.id) ? 'New' : 'Renewal'
        }
      end
    end

    def sales_split_note
      return 'none today' if todays_subscriptions.empty?
      new_count = sales_section.count { |s| s[:type] == 'New' }
      "#{new_count} new, #{todays_subscriptions.size - new_count} renewal#{'s' if (todays_subscriptions.size - new_count) != 1}"
    end

    # ── footfall ────────────────────────────────────────────────────────────

    def allowed_punches
      @allowed_punches ||= attendance_between(day_range, status: 'ALLOWED').order(:att_punch_time).to_a
    end

    def footfall
      @footfall ||= begin
        by_hour = allowed_punches.group_by { |p| in_ist(p.att_punch_time).hour }
        peak    = by_hour.max_by { |_h, rows| rows.size }
        {
          unique: allowed_punches.map(&:att_member_id).uniq.size,
          visits: allowed_punches.size,
          first:  allowed_punches.first && in_ist(allowed_punches.first.att_punch_time),
          last:   allowed_punches.last  && in_ist(allowed_punches.last.att_punch_time),
          peak_hour:  peak && peak[0],
          peak_count: peak && peak[1].size,
          by_hour: by_hour.transform_values(&:size)
        }
      end
    end

    def utilisation_note
      total = active_member_ids.size
      return 'no active members' if total.zero?
      "#{((footfall[:unique].to_f / total) * 100).round}% of #{total} active"
    end

    def footfall_section
      footfall.merge(
        peak_label: footfall[:peak_hour] ? "#{hour_label(footfall[:peak_hour])} (#{footfall[:peak_count]} in)" : '—',
        first_label: footfall[:first]&.strftime('%l:%M %p')&.strip || '—',
        last_label:  footfall[:last]&.strftime('%l:%M %p')&.strip || '—',
        utilisation: utilisation_note
      )
    end

    # 8 -> "8-9 AM", 11 -> "11 AM-12 PM", 23 -> "11 PM-12 AM"
    def hour_label(hour)
      "#{clock(hour)}-#{clock((hour + 1) % 24)}"
    end

    def clock(hour)
      display = hour % 12
      display = 12 if display.zero?
      "#{display} #{hour < 12 ? 'AM' : 'PM'}"
    end

    # ── turned away (the sales opportunity) ─────────────────────────────────

    def denied_members
      @denied_members ||= begin
        rows = attendance_between(day_range, status: 'DENIED').order(:att_punch_time).to_a
        rows.group_by(&:att_member_id).map do |mid, punches|
          last_end = latest_end_dates[mid.to_s]
          {
            member_id: mid,
            name:      member_name(mid),
            phone:     member_phone(mid),
            attempts:  punches.size,
            at:        in_ist(punches.last.att_punch_time),
            reason:    punches.last.att_reason.presence || 'Subscription expired',
            expired_on: last_end,
            days_ago:  last_end ? (date - last_end).to_i : nil
          }
        end.sort_by { |r| -r[:attempts] }
      end
    end

    def turned_away_section
      denied_members
    end

    # ── attention / action lists ────────────────────────────────────────────

    def attention_section
      {
        expiring_7:  expiring_within(7),
        lapsed_45:   lapsed_within(45),
        quiet_14:    quiet_members(14)
      }
    end

    # Active members who have not trained in a fortnight — churn before it
    # becomes a non-renewal.
    def quiet_members(days)
      return [] if active_member_ids.empty?

      since = ist_range(date - days, date)
      seen  = TrnMemberAttendance.where(att_compcode: compcode, att_status: 'ALLOWED', att_punch_time: since)
                                 .distinct.pluck(:att_member_id).to_set

      # If the turnstile recorded nobody at all for a fortnight the device is
      # down, not the gym — listing every member as "not turning up" would be
      # alarming and wrong.
      return [] if seen.empty?

      last_seen = TrnMemberAttendance.where(att_compcode: compcode, att_status: 'ALLOWED',
                                            att_member_id: active_member_ids)
                                     .group(:att_member_id).maximum(:att_punch_time)

      (active_member_ids - seen.to_a).map do |mid|
        { member_id: mid, name: member_name(mid), phone: member_phone(mid),
          last_seen: last_seen[mid] && in_ist(last_seen[mid]).to_date }
      end.sort_by { |r| r[:last_seen] || Date.new(1970, 1, 1) }
    end

    # ── membership ──────────────────────────────────────────────────────────

    def membership_section
      joined_today = MstMembersList.where(mmbr_compcode: compcode, mmbr_entry_date: date).count
      {
        active:       active_member_ids.size,
        on_roll:      MstMembersList.on_roll.where(mmbr_compcode: compcode).count,
        joined_today: joined_today,
        expiring_7:   expiring_within(7).size,
        lapsed_45:    lapsed_within(45).size
      }
    end
  end
end
