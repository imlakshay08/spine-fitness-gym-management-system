class CronController < ApplicationController
  def send_expiry_whatsapp
    return head :unauthorized unless params[:token] == ENV['CRON_SECRET']

    MembershipExpiryWhatsappJob.perform_later(:expiring)
    MembershipExpiryWhatsappJob.perform_later(:expired)

    render plain: "OK"
  end

  def sync_subscription_status
    return head :unauthorized unless params[:token] == ENV['CRON_SECRET']

    expired_count = TrnMemberSubscription
      .where("ms_end_date < ? AND ms_status = ?", Date.today, "ACTIVE")
      .update_all(ms_status: "EXPIRED", updated_at: Time.now)

    Rails.logger.info "[SyncSubscriptionStatus] #{Time.now} - Marked EXPIRED: #{expired_count}"

    render plain: "OK - Marked EXPIRED: #{expired_count}"
  end
end
