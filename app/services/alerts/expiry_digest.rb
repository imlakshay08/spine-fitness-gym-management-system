module Alerts
  # The morning list for the floor staff: who to catch at the desk today.
  #
  # This is not the same job as the member's own reminder. The member already
  # gets a WhatsApp three days out and again after it lapses. The point of this
  # one is that Vishal is standing at the gate at 7 AM when the member walks in
  # — asking in person converts far better than a message they scrolled past.
  #
  # It carries the amount, unlike the Monday list. Open-plan members each pay a
  # different figure (the plan itself is stored as 0), so "ask him to renew" is
  # useless without saying what to ask for. That is a per-member renewal price,
  # not the collections and revenue totals that stay in the owner report.
  class ExpiryDigest < Reports::GymReportBase
    SOON_DAYS   = 3    # today + the next three days
    LAPSED_DAYS = 1    # finished yesterday — see the note below

    # The lapsed window is one day, not a week, on purpose. A seven-day window
    # keeps the same four names on the list for seven mornings running, which
    # turns a worklist into wallpaper — and this arrives on the same WhatsApp
    # thread as the biometric outage alert, so the cost of being ignored is
    # paid by the message that actually matters.
    #
    # One day means each member is named at most five times across their whole
    # lifecycle: three as "finishing soon", one on the day, one the morning
    # after. That reads as a countdown rather than a stuck list.
    #
    # Keying off members who were actually turned away at the gate would be
    # better still, but it is not available: gate control deletes the
    # fingerprint template from the device, so an expired member produces no
    # punch at all. `att_status = 'DENIED'` has 307 historical rows and none in
    # the last 30 days.
    def call
      today_list   = decorate(expiring_within(0))
      soon_list    = decorate(expiring_within(SOON_DAYS).reject { |m| m[:days_left].to_i.zero? })
      lapsed_list  = decorate(lapsed_within(LAPSED_DAYS))

      {
        date:          today,
        ending_today:  today_list,
        ending_soon:   soon_list,
        just_finished: lapsed_list,
        total:         today_list.size + soon_list.size + lapsed_list.size
      }
    end

    # One WhatsApp-safe line per bucket. Template parameters may not contain
    # newlines, tabs, or runs of spaces, so the people in a bucket are joined
    # with a separator and the line breaks live in the template's fixed text.
    def self.line(entries)
      return 'None' if entries.blank?

      entries.map { |e| person(e) }.join('  ;  ')
    end

    def self.person(entry)
      phone = entry[:phone].presence || 'no number saved'
      [entry[:name], phone, entry[:plan], entry[:amount]].compact_blank.join(' ')
    end

    private

    def decorate(list)
      list.map do |entry|
        sub = latest_subscription[entry[:member_id].to_s]

        entry.merge(plan: plan_label(sub), amount: amount_label(sub))
      end
    end

    # The member's most recent subscription row — needed for the price they
    # actually paid, which `latest_end_dates` does not carry.
    def latest_subscription
      @latest_subscription ||= TrnMemberSubscription
                                 .where(ms_compcode: compcode)
                                 .order(:ms_end_date, :id)
                                 .index_by { |s| s.ms_member_id.to_s }
    end

    def plan_label(sub)
      return nil if sub.nil?

      plans_by_id[sub.ms_plan_id.to_s]&.plan_name.presence
    end

    # What they paid last time. For fixed plans this equals the plan price; for
    # open plans it is the only place the figure exists.
    def amount_label(sub)
      return nil if sub.nil?

      paid = sub.ms_final_amount.to_f
      paid = plans_by_id[sub.ms_plan_id.to_s]&.plan_final_amount.to_f if paid.zero?
      return nil if paid.zero?

      money(paid)
    end
  end
end
