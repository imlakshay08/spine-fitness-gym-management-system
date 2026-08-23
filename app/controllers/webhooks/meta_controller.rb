class Webhooks::MetaController < ApplicationController
  skip_before_action :verify_authenticity_token

  def verify
    mode      = params['hub.mode']
    token     = params['hub.verify_token']
    challenge = params['hub.challenge']

    if mode == 'subscribe' && token == ENV['WHATSAPP_WEBHOOK_TOKEN']
      render plain: challenge, status: :ok
    else
      head :forbidden
    end
  end

  def receive
    body = JSON.parse(request.body.read)

    entries = body.dig('entry') || []
    entries.each do |entry|
      changes = entry.dig('changes') || []
      changes.each do |change|
        value = change.dig('value') || {}

        # Handle delivery status updates
        statuses = value.dig('statuses') || []
        statuses.each { |status| process_status(status) }

        # Handle incoming messages from members
        messages = value.dig('messages') || []
        messages.each { |message| process_incoming(message) }
      end
    end

    head :ok
  rescue => e
    Rails.logger.error "[MetaWebhook] Error: #{e.message}"
    head :ok
  end

  private

  def process_status(status)
    message_id = status['id']
    status_val = status['status']&.upcase
    return unless message_id.present?
    return unless %w[DELIVERED READ FAILED SENT].include?(status_val)

    log = TrnWhatsappLog.find_by(wl_interakt_msg_id: message_id)
    return update_inbox_status(message_id, status_val, status) if log.nil?

    case status_val
    when 'DELIVERED'
      log.update!(wl_status: 'DELIVERED', wl_delivered_at: Time.current)
    when 'READ'
      log.update!(wl_status: 'READ', wl_read_at: Time.current)
    when 'FAILED'
      error = status.dig('errors', 0, 'message') || 'Unknown error'
      log.update!(wl_status: 'FAILED', wl_failed_reason: error)
    end

    Rails.logger.info "[MetaWebhook] Updated log #{log.id} → #{status_val}"
  end

  # Replies typed by staff in the inbox live in trn_whatsapp_inbox, not in the
  # automation log, so their ticks are updated here.
  def update_inbox_status(message_id, status_val, status)
    message = TrnWhatsappInbox.outbound.find_by(wi_wamid: message_id)
    return if message.nil?

    attrs = { wi_status: status_val, updated_at: Time.current }
    attrs[:wi_error] = status.dig('errors', 0, 'message') || 'Unknown error' if status_val == 'FAILED'
    message.update_columns(attrs)

    Rails.logger.info "[MetaWebhook] Updated inbox message #{message.id} → #{status_val}"
  end

  def process_incoming(message)
    from    = message['from']
    wamid   = message['id']
    type    = message['type'] || 'text'
    # Non-text messages still carry a caption often enough to be worth showing.
    body    = message.dig('text', 'body') || message.dig(type, 'caption')
    received_at = Time.at(message['timestamp'].to_i)

    # Skip if already saved
    return if TrnWhatsappInbox.exists?(wi_wamid: wamid)

    # Find member name if possible
    phone = from.to_s.last(10)
    member = MstMembersList.find_by(mmbr_contact: phone)

    TrnWhatsappInbox.create!(
      wi_compcode:    'SF',
      wi_from_number: from,
      wi_member_name: member&.mmbr_name,
      wi_message_type: type,
      wi_body:        body,
      wi_wamid:       wamid,
      wi_received_at: received_at,
      wi_direction:   TrnWhatsappInbox::DIRECTION_IN
    )

    Rails.logger.info "[MetaWebhook] Incoming message from #{from}: #{body}"
  rescue => e
    Rails.logger.error "[MetaWebhook] Incoming error: #{e.message}"
  end
end