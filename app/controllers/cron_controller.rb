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
    render plain: run_owner_report(:daily, on)
  end

  # Hit on the 1st of each month; reports on the month just finished.
  def send_owner_monthly_report
    return head :unauthorized unless params[:token] == ENV['CRON_SECRET']

    month = params[:month].present? ? (Date.parse("#{params[:month]}-01") rescue nil) : nil
    render plain: run_owner_report(:monthly, month)
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

  # Run inline rather than perform_later, and hand the outcome back in the
  # response body. The cron service's own execution log then shows whether the
  # report actually went out — the first run of this failed silently because
  # nothing anywhere recorded that it had not been called at all.
  def run_owner_report(kind, on)
    summary = OwnerReportWhatsappJob.perform_now(kind, compcode_param, on)
    "OK - #{summary}"
  rescue StandardError => e
    Rails.logger.error "[OwnerReport] #{kind} report failed: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace&.first(5)&.join("
")
    "ERROR - #{e.class}: #{e.message}"
  end
end
