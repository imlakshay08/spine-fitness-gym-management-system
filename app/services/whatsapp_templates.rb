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
    }
  }.freeze

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
