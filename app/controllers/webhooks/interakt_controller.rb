# app/controllers/webhooks/interakt_controller.rb
class Webhooks::InteraktController < ApplicationController
  skip_before_action :verify_authenticity_token

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
end
