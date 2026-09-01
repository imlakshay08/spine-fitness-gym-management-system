# app/controllers/webhooks/interakt_controller.rb
class Webhooks::InteraktController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :ensure_enabled

  def receive
    payload = JSON.parse(request.body.read)

    message_id = payload.dig("data", "id") || payload["id"]
    event = payload["event"] || payload["type"]

    log = TrnWhatsappLog.find_by(wl_interakt_msg_id: message_id)
    return head :ok if log.nil?

    case event
    when "message_sent"
      log.update!(wl_status: "SENT")

    when "message_delivered"
      log.update!(
        wl_status: "DELIVERED",
        wl_delivered_at: Time.current
      )

    when "message_read"
      log.update!(
        wl_status: "READ",
        wl_read_at: Time.current
      )

    when "message_failed"
      log.update!(
        wl_status: "FAILED",
        wl_failed_reason: payload.dig("data", "reason")
      )
    end

    head :ok
  end

  private

  # Interakt was replaced by the Meta Cloud API and this endpoint is no longer
  # called, but it was still open to the internet and could rewrite delivery
  # status on any message whose id an attacker could guess. It now answers 404
  # unless INTERAKT_WEBHOOK_ENABLED=true, so it can be turned back on without a
  # deploy if the legacy provider is ever needed again.
  def ensure_enabled
    return true if ENV['INTERAKT_WEBHOOK_ENABLED'].to_s.downcase == 'true'

    Rails.logger.warn "[InteraktWebhook] call to disabled endpoint from #{request.remote_ip}"
    head :not_found
    false
  end
end
