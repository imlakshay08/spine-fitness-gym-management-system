class CronController < ApplicationController
  def send_expiry_whatsapp
    return head :unauthorized unless params[:token] == ENV['CRON_SECRET']

    MembershipExpiryWhatsappJob.perform_later(:expiring)
    MembershipExpiryWhatsappJob.perform_later(:expired)

    render plain: "OK"
  end

  # Hit nightly after the gym closes (10:30 PM IST). Reports on the IST day
  # that just ended.
  def send_owner_daily_report
    return head :unauthorized unless params[:token] == ENV['CRON_SECRET']

    on = params[:date].present? ? (Date.parse(params[:date]) rescue nil) : nil
    OwnerReportWhatsappJob.perform_later(:daily, compcode_param, on)

    render plain: "OK"
  end

  # Hit on the 1st of each month; reports on the month just finished.
  def send_owner_monthly_report
    return head :unauthorized unless params[:token] == ENV['CRON_SECRET']

    month = params[:month].present? ? (Date.parse("#{params[:month]}-01") rescue nil) : nil
    OwnerReportWhatsappJob.perform_later(:monthly, compcode_param, month)

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

  private

  def compcode_param
    params[:compcode].presence || 'SF'
  end
end
