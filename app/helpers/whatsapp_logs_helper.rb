module WhatsappLogsHelper
  # Exact text the member received. Prefer the snapshot stored at send time;
  # for legacy rows (logged before wl_message_body existed) rebuild it from the
  # template + the subscription's end date. The fallback is best-effort — if
  # the subscription was renewed since, its end date will have moved on.
  def wa_message_body(log, subs_hash)
    return log.wl_message_body if log.wl_message_body.present?

    sub    = subs_hash[log.wl_subscription_id.to_s]
    expiry = sub&.ms_end_date&.strftime("%d %b %Y") || "—"
    WhatsappTemplates.render(log.wl_template_name, log.wl_member_id, expiry) ||
      "(Message preview unavailable)"
  end

  # WhatsApp-style delivery state → label, colour and tick style.
  #   QUEUED / SENT  → single grey tick
  #   DELIVERED      → double grey tick
  #   READ           → double blue tick
  #   FAILED         → red warning
  WA_STATUS = {
    "READ"      => { label: "Read",      css: "wa-read",      ticks: :double, color: "#53bdeb" },
    "DELIVERED" => { label: "Delivered", css: "wa-delivered", ticks: :double, color: "#8696a0" },
    "SENT"      => { label: "Sent",      css: "wa-sent",      ticks: :single, color: "#8696a0" },
    "QUEUED"    => { label: "Queued",    css: "wa-queued",    ticks: :single, color: "#8696a0" },
    "ACCEPTED"  => { label: "Sent",      css: "wa-sent",      ticks: :single, color: "#8696a0" },
    "FAILED"    => { label: "Failed",    css: "wa-failed",    ticks: :failed, color: "#e74c3c" }
  }.freeze

  def wa_status_info(status)
    WA_STATUS[status.to_s.upcase] ||
      { label: status.to_s.titleize.presence || "Unknown", css: "wa-queued", ticks: :single, color: "#8696a0" }
  end

  def wa_ticks_html(status)
    info = wa_status_info(status)
    icon =
      case info[:ticks]
      when :double then "fa-solid fa-check-double"
      when :failed then "fa-solid fa-circle-exclamation"
      else "fa-solid fa-check"
      end
    content_tag(:span, content_tag(:i, "", class: icon), class: "wa-tick", style: "color:#{info[:color]}")
  end

  def wa_status_badge(status)
    info = wa_status_info(status)
    content_tag(:span, class: "wa-badge #{info[:css]}") do
      safe_join([wa_ticks_html(status), content_tag(:span, info[:label], class: "wa-badge-label")])
    end
  end

  # Timestamps are stored UTC; the gym reads IST. Without this a 10:00 AM send
  # displayed as 04:30 AM.
  IST = 'Asia/Kolkata'.freeze

  def wa_ist(dt)
    dt && dt.in_time_zone(IST)
  end

  def wa_time(dt)
    return content_tag(:span, "—", class: "wa-muted") if dt.blank?

    local = dt.in_time_zone(IST)
    content_tag(:span, local.strftime("%d %b %Y"), class: "wa-date") +
      content_tag(:span, local.strftime("%I:%M %p"), class: "wa-clock")
  end
end
