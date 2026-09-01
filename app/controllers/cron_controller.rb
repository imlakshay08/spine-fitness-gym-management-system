class CronController < ApplicationController
  def send_expiry_whatsapp
    return head :unauthorized unless valid_cron_token?

    MembershipExpiryWhatsappJob.perform_later(:expiring)
    MembershipExpiryWhatsappJob.perform_later(:expired)

    render plain: "OK"
  end

  # Hit nightly after the gym closes (10:30 PM IST). Reports on the IST day
  # that just ended.
  def send_owner_daily_report
    return head :unauthorized unless valid_cron_token?

    on = params[:date].present? ? (Date.parse(params[:date]) rescue nil) : nil
    render plain: run_owner_report(:daily, on)
  end

  # Hit on the 1st of each month; reports on the month just finished.
  def send_owner_monthly_report
    return head :unauthorized unless valid_cron_token?

    month = params[:month].present? ? (Date.parse("#{params[:month]}-01") rescue nil) : nil
    render plain: run_owner_report(:monthly, month)
  end

  # Hit every 15 minutes. Only speaks up while the gym is open, and at most
  # once every 2 hours for the same problem.
  def check_biometric
    return head :unauthorized unless params[:token] == ENV['CRON_SECRET']

    render plain: run_staff_alert(:biometric)
  end

  # Hit Monday at 12:00 IST (06:30 UTC).
  def send_staff_weekly
    return head :unauthorized unless params[:token] == ENV['CRON_SECRET']

    render plain: run_staff_alert(:weekly)
  end

  def sync_subscription_status
    return head :unauthorized unless valid_cron_token?

    expired_count = TrnMemberSubscription
      .where("ms_end_date < ? AND ms_status = ?", Date.today, "ACTIVE")
      .update_all(ms_status: "EXPIRED", updated_at: Time.now)

    Rails.logger.info "[SyncSubscriptionStatus] #{Time.now} - Marked EXPIRED: #{expired_count}"

    render plain: "OK - Marked EXPIRED: #{expired_count}"
  end

  private

  # Constant-time, so a caller cannot learn the secret one byte at a time by
  # measuring how long the comparison takes. Hashing first keeps the compare
  # length-independent — secure_compare raises on a length mismatch, which
  # would itself leak how long the real token is.
  def valid_cron_token?
    expected = ENV['CRON_SECRET'].to_s
    given    = params[:token].to_s
    return false if expected.empty? || given.empty?

    ActiveSupport::SecurityUtils.secure_compare(
      ::Digest::SHA256.hexdigest(given),
      ::Digest::SHA256.hexdigest(expected)
    )
  end

  def compcode_param
    params[:compcode].presence || 'SF'
  end

  # Run inline rather than perform_later, and hand the outcome back in the
  # response body. The cron service's own execution log then shows whether the
  # report actually went out — the first run of this failed silently because
  # nothing anywhere recorded that it had not been called at all.
  def run_staff_alert(kind)
    summary = StaffAlertWhatsappJob.perform_now(kind, compcode_param)
    "OK - #{summary}"
  rescue StandardError => e
    Rails.logger.error "[StaffAlert] #{kind} failed: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace&.first(5)&.join("
")
    "ERROR - #{e.class}: #{e.message}"
  end

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
