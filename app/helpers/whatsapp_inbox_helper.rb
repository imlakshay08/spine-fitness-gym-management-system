module WhatsappInboxHelper
  IST = 'Asia/Kolkata'.freeze

  # Every WhatsApp timestamp is stored in UTC. The gym reads them in IST.
  def wa_ist(time)
    time && time.in_time_zone(IST)
  end

  def wa_clock(time)
    local = wa_ist(time)
    local ? local.strftime('%l:%M %p').strip : ''
  end

  def wa_day_label(time)
    local = wa_ist(time)
    return '' unless local

    today = Time.current.in_time_zone(IST).to_date
    case local.to_date
    when today          then 'Today'
    when today - 1      then 'Yesterday'
    else
      local.year == today.year ? local.strftime('%d %B') : local.strftime('%d %B %Y')
    end
  end

  # Sidebar stamp: clock today, "Yesterday", then dates — same as WhatsApp.
  def wa_list_stamp(time)
    local = wa_ist(time)
    return '' unless local

    today = Time.current.in_time_zone(IST).to_date
    case local.to_date
    when today     then local.strftime('%l:%M %p').strip
    when today - 1 then 'Yesterday'
    else
      local.year == today.year ? local.strftime('%d %b') : local.strftime('%d/%m/%y')
    end
  end

  def wa_status_class(status)
    case status.to_s.upcase
    when 'READ'                then 'is-read'
    when 'DELIVERED'           then 'is-delivered'
    when 'FAILED', 'UNDELIVERED' then 'is-failed'
    when 'SENDING'             then 'is-sending'
    else 'is-sent'
    end
  end

  def wa_ticks(status)
    icon =
      case status.to_s.upcase
      when 'READ', 'DELIVERED'     then 'fa-solid fa-check-double'
      when 'FAILED', 'UNDELIVERED' then 'fa-solid fa-circle-exclamation'
      when 'SENDING'               then 'fa-regular fa-clock'
      else 'fa-solid fa-check'
      end

    tag.span(tag.i('', class: icon), class: "wai-ticks #{wa_status_class(status)}")
  end

  def wa_status_label(status)
    case status.to_s.upcase
    when 'READ'      then 'Read'
    when 'DELIVERED' then 'Delivered'
    when 'FAILED'    then 'Failed'
    when 'QUEUED'    then 'Queued'
    when 'SENDING'   then 'Sending'
    else 'Sent'
    end
  end

  def wa_avatar_tone(name)
    # Stable colour per contact so faces in the list stay recognisable.
    %w[a b c d e f][name.to_s.sum % 6]
  end
end
