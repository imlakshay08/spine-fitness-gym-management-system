# Single source of truth for the WhatsApp templates the gym sends.
#
# The exact wording, the friendly label shown to staff, and the parameter
# order all live here so the sender job (MembershipExpiryWhatsappJob) and the
# WhatsApp Logs screen can never drift apart. Meta's own template preview
# fills {{1}}/{{2}} with sample values ("MEM001", a demo date) — the real
# values we substitute are the member id and the subscription end date, in
# that order, exactly as the job passes them to Meta::SendWhatsapp.
module WhatsappTemplates
  TEMPLATES = {
    "membership_expiry_alert_new" => {
      label:       "Expiry Reminder",
      description: "Sent 3 days before a membership expires",
      icon:        "fa-solid fa-hourglass-half",
      tone:        "warning",
      body: ->(member_id, expiry_date) do
        "Your membership at Spine Fitness (ID: #{member_id}) will expire on " \
        "#{expiry_date}. This is an automated notification."
      end
    },
    "membership_expired_alert_new" => {
      label:       "Expired Alert",
      description: "Sent after a membership has already expired",
      icon:        "fa-solid fa-triangle-exclamation",
      tone:        "danger",
      body: ->(member_id, expiry_date) do
        "Your membership at Spine Fitness (ID: #{member_id}) expired on " \
        "#{expiry_date}. This is an automated notification."
      end
    },
    "subscription_receipt" => {
      label:       "Subscription Receipt",
      description: "Sent the moment a subscription is created or renewed",
      icon:        "fa-solid fa-receipt",
      tone:        "info",
      # Order must match the {{1}}..{{7}} placeholders approved in Meta and the
      # body_values array built by SubscriptionReceiptWhatsappJob.
      body: ->(name, receipt_no, plan, amount, mode, start_date, end_date) do
        <<~MSG.strip
          Hi #{name}, your Spine Fitness membership is confirmed.

          Receipt: #{receipt_no}
          Plan: #{plan}
          Amount Paid: Rs. #{amount} (#{mode})
          Valid: #{start_date} to #{end_date}

          Your receipt is attached. Thank you for choosing Spine Fitness!
        MSG
      end
    },
    "gym_owner_report" => {
      label:       "Owner Report",
      description: "Daily and monthly business summary sent to the owner",
      icon:        "fa-solid fa-chart-line",
      tone:        "info",
      # One template serves both reports — {{2}} carries "daily" or "monthly"
      # and {{3}} the period, so only one Meta approval is needed.
      body: ->(owner, kind, period, collected, subs, visits, turned_away, attention) do
        <<~MSG.strip
          Hi #{owner}, here is your Spine Fitness #{kind} report for #{period}.

          Collected: Rs. #{collected}
          New subscriptions: #{subs}
          Member visits: #{visits}
          Turned away (expired): #{turned_away}
          Needs attention: #{attention}

          The full report is attached.
        MSG
      end
    },
    "alert_for_staff" => {
      label:       "Staff Alert",
      description: "Sent to gym staff when something in the software needs fixing",
      icon:        "fa-solid fa-triangle-exclamation",
      tone:        "danger",
      # Worded to match Meta's "System outages" utility example: a service
      # status notification tied to the recipient's own account, naming the
      # affected service, with no promotional or persuasive content. The
      # earlier generic "Problem / Details / What to do" phrasing was
      # classified as Marketing, which subjected it to the per-recipient
      # marketing cap — one alert was dropped undelivered because of it.
      body: ->(name, service, status, action) do
        <<~MSG.strip
          Hi #{name}, we have detected a service outage on your Spine Fitness account.

          Affected service: #{service}
          Current status: #{status}
          Recommended action: #{action}

          We apologize for the inconvenience.
        MSG
      end
    },
    "staff_morning_list" => {
      label:       "Staff Morning List",
      description: "Members whose membership is finishing — sent only on days there are some",
      icon:        "fa-solid fa-user-clock",
      tone:        "warning",
      # Written for Vishal and Mani, not for a manager. Short sentences, no
      # word longer than it has to be, and every line says who to talk to and
      # how much to ask for. The three lists arrive as one line each because
      # Meta rejects newlines inside a parameter — the line breaks below are
      # fixed template text.
      body: ->(name, ending_today, ending_soon, just_finished) do
        <<~MSG.strip
          Good morning #{name}.

          Please talk to these members. Ask them to pay and start their new membership.

          Finishing today: #{ending_today}
          Finishing in next 3 days: #{ending_soon}
          Finished yesterday, gate will stop them now: #{just_finished}

          Thank you.
        MSG
      end
    },
    "staff_weekly_list" => {
      label:       "Staff Weekly List",
      description: "Monday list of members to call and data to fix",
      icon:        "fa-solid fa-list-check",
      tone:        "info",
      body: ->(name, period, to_call, to_fix, numbers) do
        <<~MSG.strip
          Hi #{name}, here is this week's list from the Spine Fitness software (#{period}).

          Members to call: #{to_call}
          Fingerprint problems to fix: #{to_fix}
          Wrong phone numbers to correct: #{numbers}

          The full list with names and numbers is attached.
        MSG
      end
    }
  }.freeze

  # Templates that are not messages to a member. The WhatsApp Logs screen is a
  # member communication history, so these are kept out of it (the rows are
  # still written, for audit and debugging).
  #
  # 'staff_alert' is the name the staff alert used before it was renamed to
  # 'alert_for_staff' to get a fresh Meta approval. Alerts sent under the old
  # name are still in the log, so the old name has to stay on this list
  # permanently — dropping it at the rename is exactly what made those alerts
  # appear on the WhatsApp Logs screen as "Deleted member" rows.
  INTERNAL = %w[gym_owner_report alert_for_staff staff_alert staff_weekly_list
                staff_morning_list].freeze

  def self.internal?(name)
    INTERNAL.include?(name.to_s)
  end

  def self.member_facing
    TEMPLATES.reject { |name, _| INTERNAL.include?(name) }
  end

  def self.known?(name)
    TEMPLATES.key?(name)
  end

  def self.label(name)
    TEMPLATES.dig(name, :label) || name.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
  end

  def self.icon(name)
    TEMPLATES.dig(name, :icon) || "fa-solid fa-comment-dots"
  end

  def self.tone(name)
    TEMPLATES.dig(name, :tone) || "info"
  end

  # Rebuild the human-readable message body from the same parameters the job
  # sends to Meta. Returns nil for an unknown template so callers can fall back.
  # Templates take different numbers of parameters, so callers pass whatever
  # that template needs. A mismatched count returns nil rather than raising —
  # the logs screen then falls back to the body snapshot stored at send time.
  def self.render(name, *values)
    tmpl = TEMPLATES[name]
    return nil unless tmpl

    fn = tmpl[:body]
    return nil unless fn.arity.negative? || fn.arity == values.size

    fn.call(*values)
  end
end
