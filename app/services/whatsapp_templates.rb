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
  def self.render(name, member_id, expiry_date)
    tmpl = TEMPLATES[name]
    return nil unless tmpl

    tmpl[:body].call(member_id, expiry_date)
  end
end
