class CronController < ApplicationController
  def send_expiry_whatsapp
    return head :unauthorized unless params[:token] == ENV['CRON_SECRET']

    MembershipExpiryWhatsappJob.perform_later(:expiring)
    MembershipExpiryWhatsappJob.perform_later(:expired)

    render plain: "OK"
  end
end
