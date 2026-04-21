class Webhooks::MetaController < ApplicationController
  skip_before_action :verify_authenticity_token

  # Webhook verification by Meta
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

  # Incoming webhook events
  def receive
    body = JSON.parse(request.body.read)

    entries = body.dig('entry') || []
    entries.each do |entry|
      changes = entry.dig('changes') || []
      changes.each do |change|
        value = change.dig('value') || {}
        statuses = value.dig('statuses') || []

        statuses.each do |status|
          process_status(status)
        end
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
    return unless log

    case status_val
    when 'DELIVERED'
      log.update!(
        wl_status: 'DELIVERED',
        wl_delivered_at: Time.current
      )
    when 'READ'
      log.update!(
        wl_status: 'READ',
        wl_read_at: Time.current
      )
    when 'FAILED'
      error = status.dig('errors', 0, 'message') || 'Unknown error'
      log.update!(
        wl_status: 'FAILED',
        wl_failed_reason: error
      )
    end

    Rails.logger.info "[MetaWebhook] Updated log #{log.id} → #{status_val}"
  end
end