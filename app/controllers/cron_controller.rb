class CronController < ApplicationController
    def send_expiry_whatsapp
    return head :unauthorized unless params[:token] == ENV['CRON_SECRET']

    MembershipExpiryWhatsappJob.perform_now
    render plain: "OK"
  end
end
