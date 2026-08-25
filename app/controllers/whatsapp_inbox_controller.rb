class WhatsappInboxController < ApplicationController
  before_action :require_inbox_login
  before_action :get_user_access_permissions, only: [:index]

  IST = 'Asia/Kolkata'.freeze

  # ── Full page ────────────────────────────────────────────────────────────
  def index
    @active_number = TrnWhatsappInbox.normalize_number(params[:number]) || newest_thread_number
    mark_seen(@active_number)

    @conversations = build_conversations
    @active_chat   = @conversations.detect { |c| c[:number] == @active_number }
    @active_number = nil unless @active_chat
    @total_unread  = @conversations.sum { |c| c[:unread] }

    if @active_chat
      @messages     = build_timeline(@active_number)
      @context      = build_context(@active_chat)
      @session_open = session_open?(@active_number)
      @cursor       = @messages.last ? @messages.last[:at].to_i : 0
    else
      @messages = []
      @cursor   = 0
    end
  end

  # ── Open a conversation without reloading the page ───────────────────────
  def thread
    number = TrnWhatsappInbox.normalize_number(params[:number])
    return render(json: { ok: false, error: 'Unknown conversation.' }, status: :not_found) if number.blank?

    mark_seen(number)
    conversations = build_conversations
    chat = conversations.detect { |c| c[:number] == number }
    return render(json: { ok: false, error: 'Unknown conversation.' }, status: :not_found) if chat.nil?

    items = build_timeline(number)

    render json: {
      ok:                 true,
      number:             number,
      name:               chat[:name],
      initial:            chat[:initial],
      tone:               helpers.wa_avatar_tone(chat[:name]),
      phone:              pretty_number(number),
      session_open:       session_open?(number),
      cursor:             items.last ? items.last[:at].to_i : 0,
      messages_html:      render_messages(items),
      context_html:       render_partial('context', context: build_context(chat)),
      conversations_html: render_conversations(conversations, number),
      total_unread:       conversations.sum { |c| c[:unread] }
    }
  end

  # ── Polled every few seconds: new messages + sidebar + delivery ticks ────
  def poll
    number = TrnWhatsappInbox.normalize_number(params[:number])
    since  = params[:since].to_i

    # The staff member is looking at this thread, so anything that lands while
    # the tab has focus is already read.
    mark_seen(number) if number.present? && params[:focused].to_s == '1'

    conversations = build_conversations
    items         = number.present? ? build_timeline(number, after: since) : []

    render json: {
      ok:                 true,
      total_unread:       conversations.sum { |c| c[:unread] },
      conversations_html: render_conversations(conversations, number),
      messages_html:      items.any? ? render_messages(items) : '',
      statuses:           number.present? ? recent_statuses(number) : {},
      session_open:       number.present? ? session_open?(number) : false
    }
  end

  # ── Send a message ───────────────────────────────────────────────────────
  def reply
    number = TrnWhatsappInbox.normalize_number(params[:number])
    text   = params[:text].to_s.strip

    return render(json: { ok: false, error: 'Pick a conversation first.' }, status: :unprocessable_entity) if number.blank?
    return render(json: { ok: false, error: 'Message cannot be empty.' },  status: :unprocessable_entity) if text.blank?

    # A dropped connection to Graph must still leave the message on screen,
    # marked failed, instead of blowing up the whole request.
    response =
      begin
        Meta::SendWhatsapp.send_text(phone: number, message: text)
      rescue StandardError => e
        Rails.logger.error "[WhatsappInbox] send failed: #{e.class} #{e.message}"
        { http_code: 0, body: {}, raw: e.message }
      end

    delivered = response[:http_code].to_i.between?(200, 299)
    wamid     = response.dig(:body, 'messages', 0, 'id')
    staff     = staff_name

    message = TrnWhatsappInbox.create!(
      wi_compcode:     compcode,
      wi_from_number:  number,
      wi_member_name:  member_for(number)&.mmbr_name,
      wi_message_type: 'text',
      wi_body:         text,
      wi_wamid:        wamid,
      wi_received_at:  Time.current,
      wi_direction:    TrnWhatsappInbox::DIRECTION_OUT,
      wi_status:       delivered ? 'SENT' : 'FAILED',
      wi_error:        delivered ? nil : meta_error(response),
      wi_replied:      1,
      wi_replied_by:   staff,
      wi_replied_at:   Time.current,
      wi_seen_at:      Time.current
    )

    if delivered
      TrnWhatsappInbox
        .inbound
        .where(wi_compcode: compcode, wi_from_number: number, wi_replied: 0)
        .update_all(wi_replied: 1, wi_replied_at: Time.current, wi_replied_by: staff, updated_at: Time.current)
    end

    item = outbound_item(message)

    render json: {
      ok:     delivered,
      error:  delivered ? nil : (message.wi_error.presence || 'WhatsApp rejected the message.'),
      key:    item[:key],
      cursor: item[:at].to_i,
      html:   render_messages([item])
    }
  end

  private

  def compcode
    session[:loggedUserCompCode].presence || 'SF'
  end

  def staff_name
    session[:loggedUserName].presence || session[:loggedUserFirstName].presence || 'Staff'
  end

  def newest_thread_number
    TrnWhatsappInbox.where(wi_compcode: compcode).order(wi_received_at: :desc).limit(1).pluck(:wi_from_number).first
  end

  # ── Sidebar ──────────────────────────────────────────────────────────────
  def build_conversations
    rows    = TrnWhatsappInbox.where(wi_compcode: compcode).order(wi_received_at: :desc).to_a
    grouped = rows.group_by { |r| r.wi_from_number.to_s }
    members = members_by_phone(grouped.keys)

    grouped.map do |number, messages|
      last   = messages.first # rows arrive newest-first
      member = members[number.last(10)]
      name   = member&.mmbr_name.presence ||
               messages.map(&:wi_member_name).reject(&:blank?).first.presence ||
               pretty_number(number)

      {
        number:      number,
        member:      member,
        name:        name,
        initial:     name.to_s.strip.first.to_s.upcase.presence || '?',
        preview:     preview_for(last),
        last_at:     last.wi_received_at,
        last_dir:    last.inbound? ? 'in' : 'out',
        last_status: last.wi_status,
        unread:      messages.count { |m| m.inbound? && m.wi_seen_at.nil? }
      }
    end.sort_by { |c| -c[:last_at].to_i }
  end

  def preview_for(message)
    return "Reacted #{message.wi_body}" if message.reaction?
    return message.wi_body.to_s.tr("\n", ' ') if message.wi_body.present?

    case message.wi_message_type.to_s
    when 'image'          then '📷 Photo'
    when 'video'          then '🎥 Video'
    when 'audio', 'voice' then '🎤 Voice message'
    when 'document'       then '📄 Document'
    when 'location'       then '📍 Location'
    else '📎 Attachment'
    end
  end

  # ── Thread ───────────────────────────────────────────────────────────────
  # One list merging what the member sent, what staff replied and what the
  # automation fired — ordered by the clock, which is what a chat is.
  def build_timeline(number, after: nil)
    items     = []
    reactions = reactions_for(number)

    TrnWhatsappInbox
      .where(wi_compcode: compcode, wi_from_number: number)
      .order(:wi_received_at, :id)
      .each do |message|
        # A reaction is drawn on the message it belongs to, never as a bubble
        # of its own — that is what WhatsApp itself does.
        next if message.reaction?

        if message.outbound?
          items << outbound_item(message, reactions)
        else
          items << {
            key:       "in-#{message.id}",
            dir:       'in',
            kind:      'member',
            body:      message.wi_body,
            at:        message.wi_received_at,
            media:     message.wi_media_url,
            msg_type:  message.wi_message_type,
            reactions: reactions[message.wi_wamid.to_s]
          }

          # Replies written before outgoing messages had rows of their own.
          if message.wi_reply_text.present? && message.wi_replied_at.present?
            items << {
              key:    "rep-#{message.id}",
              dir:    'out',
              kind:   'staff',
              author: message.wi_replied_by.presence || 'Staff',
              body:   message.wi_reply_text,
              at:     message.wi_replied_at,
              status: 'SENT'
            }
          end
        end
      end

    member = member_for(number)
    if member
      TrnWhatsappLog
        .where(wl_compcode: compcode, wl_member_id: member.id.to_s)
        .where.not(wl_sent_at: nil)
        .order(:wl_sent_at, :id)
        .each do |log|
          items << {
            key:       "log-#{log.id}",
            dir:       'out',
            kind:      'auto',
            author:    'Automated',
            reactions: reactions[log.wl_interakt_msg_id.to_s],
            body:     log.wl_message_body.presence || log.wl_template_name.to_s.humanize,
            at:       log.wl_sent_at,
            status:   log.wl_status,
            # wl_failed_reason also holds the raw success payload on older
            # rows, so it is only meaningful when the send actually failed.
            error:    (log.wl_status.to_s.upcase == 'FAILED' ? log.wl_failed_reason : nil),
            template: log.wl_template_name
          }
        end
    end

    items.sort_by! { |item| [item[:at].to_i, item[:key]] }
    items = items.select { |item| item[:at].to_i > after.to_i } if after.to_i > 0
    items
  end

  def outbound_item(message, reactions = {})
    {
      key:       "out-#{message.id}",
      dir:       'out',
      kind:      message.wi_replied_by.present? ? 'staff' : 'auto',
      author:    message.wi_replied_by.presence || 'Automated',
      body:      message.wi_body,
      at:        message.wi_received_at,
      status:    message.wi_status.presence || 'SENT',
      error:     message.wi_error,
      media:     message.wi_media_url,
      msg_type:  message.wi_message_type,
      reactions: reactions[message.wi_wamid.to_s]
    }
  end

  # Emoji reactions keyed by the wamid of the message they belong to. Members
  # most often react to an automated message, so logs are matched too.
  def reactions_for(number)
    TrnWhatsappInbox
      .where(wi_compcode: compcode, wi_from_number: number, wi_message_type: 'reaction')
      .where.not(wi_reaction_to: nil)
      .order(:wi_received_at)
      .group_by { |r| r.wi_reaction_to.to_s }
      .transform_values { |rows| rows.map { |r| r.wi_body.to_s }.reject(&:blank?) }
  end

  # Ticks move after the bubble is already on screen, so the poll hands back
  # the current state of everything sent recently.
  def recent_statuses(number)
    statuses = {}
    window   = 7.days.ago

    TrnWhatsappInbox
      .outbound
      .where(wi_compcode: compcode, wi_from_number: number)
      .where('wi_received_at >= ?', window)
      .each { |m| statuses["out-#{m.id}"] = m.wi_status.presence || 'SENT' }

    member = member_for(number)
    if member
      TrnWhatsappLog
        .where(wl_compcode: compcode, wl_member_id: member.id.to_s)
        .where('wl_sent_at >= ?', window)
        .each { |log| statuses["log-#{log.id}"] = log.wl_status.to_s }
    end

    statuses
  end

  # ── Member panel ─────────────────────────────────────────────────────────
  def build_context(chat)
    member = chat[:member]
    ctx    = { chat: chat, member: member }
    return ctx unless member

    subscription = TrnMemberSubscription
                     .where(ms_compcode: compcode, ms_member_id: member.id.to_s)
                     .order(ms_end_date: :desc)
                     .first

    ctx[:subscription] = subscription
    ctx[:plan]         = subscription && MstMembershipPlan.find_by(id: subscription.ms_plan_id)
    ctx[:days_left]    = subscription && (subscription.ms_end_date - Date.current).to_i
    ctx[:last_visit]   = TrnMemberAttendance
                           .where(att_compcode: compcode, att_member_id: member.id.to_s)
                           .order(att_punch_time: :desc)
                           .limit(1)
                           .pluck(:att_punch_time)
                           .first
    ctx[:alerts_sent]  = TrnWhatsappLog.where(wl_compcode: compcode, wl_member_id: member.id.to_s).count
    ctx
  end

  # ── Helpers ──────────────────────────────────────────────────────────────
  def members_by_phone(numbers)
    phones = numbers.map { |n| n.to_s.last(10) }.uniq
    return {} if phones.empty?

    MstMembersList
      .where(mmbr_compcode: compcode, mmbr_contact: phones)
      .index_by { |m| m.mmbr_contact.to_s }
  end

  def member_for(number)
    @member_cache ||= {}
    @member_cache[number] ||= MstMembersList.find_by(mmbr_compcode: compcode, mmbr_contact: number.to_s.last(10))
  end

  def session_open?(number)
    last_in = TrnWhatsappInbox
                .inbound
                .where(wi_compcode: compcode, wi_from_number: number)
                .maximum(:wi_received_at)

    last_in.present? && last_in > TrnWhatsappInbox::SESSION_WINDOW.ago
  end

  def mark_seen(number)
    return if number.blank?

    TrnWhatsappInbox
      .unseen
      .where(wi_compcode: compcode, wi_from_number: number)
      .update_all(wi_seen_at: Time.current, updated_at: Time.current)
  end

  def pretty_number(number)
    digits = number.to_s.gsub(/\D/, '')
    digits.length >= 12 ? "+#{digits[0..1]} #{digits[2..6]} #{digits[7..]}" : "+#{digits}"
  end

  def meta_error(response)
    response.dig(:body, 'error', 'message').presence || "Send failed (HTTP #{response[:http_code]})"
  end

  # ── Rendering ────────────────────────────────────────────────────────────
  def render_messages(items)
    return '' if items.blank?
    render_to_string(partial: 'whatsapp_inbox/message', collection: items, as: :item, formats: [:html]).to_s
  end

  def render_conversations(conversations, active_number)
    render_partial('conversation_list', conversations: conversations, active_number: active_number)
  end

  def render_partial(name, locals)
    render_to_string(partial: "whatsapp_inbox/#{name}", locals: locals, formats: [:html]).to_s
  end

  # JSON callers get a status code they can act on instead of a login page.
  def require_inbox_login
    if json_request?
      @securedlogged = false
      current_user
      render(json: { ok: false, error: 'session_expired' }, status: :unauthorized) unless @securedlogged
    else
      require_login
    end
  end

  def json_request?
    request.format.json? || request.xhr?
  end
end
