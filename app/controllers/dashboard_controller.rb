class DashboardController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct,:payment_status,:total_paid,:due_amount
    def index
      @compcode = session[:loggedUserCompCode]

      # Stock
      @stock_list = MstStockList.where(sl_compcode: @compcode)

      # Subscriptions (LATEST PER MEMBER ONLY)
      @latest_subs = latest_subscriptions

      # Categorisation
      @expired_subs = @latest_subs.where(
        "ms_end_date < ?", Date.today
      )

      @expiring_subs = @latest_subs.where(
        "ms_end_date BETWEEN ? AND ?",
        Date.today,
        Date.today + 7
      )

      @active_subs = @latest_subs.where(
        "ms_end_date > ?", Date.today + 7
      )

      # Dashboard counters
      @active_count   = @active_subs.count
      @expired_count  = @expired_subs.count
      @expiring_count = @expiring_subs.count

      # Payment metrics
      @today_collection = todays_collection
      @due_members      = members_with_due
    end

    def latest_subscriptions
  TrnMemberSubscription
    .where(ms_compcode: session[:loggedUserCompCode])
    .joins("
      INNER JOIN (
        SELECT ms_member_id, MAX(ms_end_date) AS max_end_date
        FROM trn_member_subscriptions
        WHERE ms_compcode='#{session[:loggedUserCompCode]}'
        GROUP BY ms_member_id
      ) latest
      ON latest.ms_member_id = trn_member_subscriptions.ms_member_id
      AND latest.max_end_date = trn_member_subscriptions.ms_end_date
    ")
  end

    def total_paid(subscription)
    TrnPayment
      .where(pay_ref_type: 'MEMBER_SUBSCRIPTION', pay_ref_id: subscription.id)
      .sum(:pay_amount).to_f
  end

  def due_amount(subscription)
    subscription.ms_final_amount.to_f - total_paid(subscription)
  end

  def payment_status(subscription)
    paid = total_paid(subscription)
    final = subscription.ms_final_amount.to_f

    return "PAID" if paid >= final
    return "PARTIAL" if paid > 0
    "DUE"
  end

    def todays_collection
    TrnPayment
      .where(pay_compcode: session[:loggedUserCompCode])
      .where(pay_date: Date.today)
      .sum(:pay_amount).to_f
  end

  def members_with_due
    latest_subscriptions.select do |sub|
      due_amount(sub) > 0
    end
  end

      
end
