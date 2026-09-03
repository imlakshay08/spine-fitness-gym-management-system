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
    LAPSED_DAYS = 1    # finished yesterday only

    # Two buckets, one day each: finishing today, and finished yesterday. No
    # "next few days" list — a membership that ends on Friday is not something
    # to raise on Tuesday, and a wider window would put the same names in front
    # of staff every morning until they stopped reading any of it. That matters
    # more than usual here, because the biometric outage alert lands on the
    # same WhatsApp thread and cannot afford to be ignored.
    #
    # As built, a member is named at most twice in their whole lifecycle: on
    # the last day, and the morning after.
    #
    # Keying off members actually turned away at the gate would be better
    # still, but it is not available: gate control deletes the fingerprint
    # template from the device, so an expired member produces no punch at all.
    # `att_status = 'DENIED'` has 307 historical rows and none in 30 days.
    def call
      today_list  = decorate(expiring_within(0))
      lapsed_list = decorate(lapsed_within(LAPSED_DAYS))

      {
        date:          today,
        ending_today:  today_list,
        just_finished: lapsed_list,
        total:         today_list.size + lapsed_list.size
      }
    end

    # One WhatsApp-safe line per bucket. Template parameters may not contain
    # newlines, tabs, or runs of spaces, so the people in a bucket are joined
    # into a single string and the line breaks live in the template's fixed
    # text. Most days this is one or two people, so it stays short.
    #
    #   Aryan Saxena (9876543210) Rs. 2500
    #   Aryan Saxena (9876543210) Rs. 2500, Rajat Sharma (9811122233) Rs. 7000
    def self.line(entries)
      return 'None' if entries.blank?

      entries.map { |e| person(e) }.join(', ')
    end

    # Name, number, price. The plan name is left out on purpose — it is the
    # amount staff need in order to ask, and adding "Quarterly" as well made
    # the line long enough to wrap badly on a phone.
    def self.person(entry)
      name  = entry[:name].to_s.strip
      phone = entry[:phone].presence
      parts = [phone ? "#{name} (#{phone})" : "#{name} (no number saved)"]
      parts << entry[:amount] if entry[:amount].present?
      parts.join(' ')
    end

    private

    def decorate(list)
      list.map do |entry|
        sub = latest_subscription[entry[:member_id].to_s]

        entry.merge(amount: amount_label(sub))
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

    # What they paid last time. For fixed plans this equals the plan price; for
    # open plans it is the only place the figure exists, which is why this
    # message carries money at all.
    #
    # Written without a thousands separator — "Rs. 7000", not "Rs. 7,000" — so
    # the comma between two people cannot be mistaken for part of a price.
    def amount_label(sub)
      return nil if sub.nil?

      paid = sub.ms_final_amount.to_f
      paid = plans_by_id[sub.ms_plan_id.to_s]&.plan_final_amount.to_f if paid.zero?
      return nil if paid.zero?

      "Rs. #{paid.round}"
    end
  end
end
