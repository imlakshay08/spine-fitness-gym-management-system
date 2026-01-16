class DashboardController < ApplicationController
  before_action :require_login
  before_action :get_user_access_permissions
  skip_before_action :verify_authenticity_token
  include ErpModule::Common

  helper_method :currency_formatted, :year_month_days_formatted,
                :formatted_date, :set_ent, :set_dct,
                :payment_status, :total_paid, :due_amount

  def index
    @compcode = session[:loggedUserCompCode]

    # Stock
    @stock_list = MstStockList.where(sl_compcode: @compcode)

    # Latest subscriptions
    @latest_subs = latest_subscriptions.to_a

    # ---- PRELOAD DATA IN BULK ----
    preload_members
    preload_plans
    preload_payments

    # Categorisation
    today = Date.today

    @expired_subs  = @latest_subs.select { |s| s.ms_end_date < today }
    @expiring_subs = @latest_subs.select { |s| s.ms_end_date.between?(today, today + 7) }
    @active_subs   = @latest_subs.select { |s| s.ms_end_date > today + 7 }

    # Counters
    @active_count   = @active_subs.size
    @expired_count  = @expired_subs.size
    @expiring_count = @expiring_subs.size

    # Metrics
    @today_collection = todays_collection
    @due_members = @latest_subs.select { |s| due_amount(s) > 0 }
  end

  # ---------------- BULK LOADERS ----------------

  def preload_members
    member_ids = @latest_subs.map(&:ms_member_id).uniq

    @members_map = MstMembersList
      .where(mmbr_compcode: @compcode, id: member_ids)
      .each_with_object({}) do |m, h|
        h[m.id.to_s] = m
      end
  end


  def preload_plans
    plan_ids = @latest_subs.map(&:ms_plan_id).uniq

    @plans_map = MstMembershipPlan
      .where(plan_compcode: @compcode, id: plan_ids)
      .each_with_object({}) do |p, h|
        h[p.id.to_s] = p
      end
  end


  def preload_payments
    sub_ids = @latest_subs.map(&:id).map(&:to_s)

    raw = TrnPayment
      .where(
        pay_ref_type: 'MEMBER_SUBSCRIPTION',
        pay_ref_id: sub_ids
      )
      .group(:pay_ref_id)
      .sum(:pay_amount)

    @payments_map = raw.transform_keys(&:to_s)
  end


  # ---------------- HELPERS (UNCHANGED API) ----------------

  def total_paid(subscription)
    @payments_map[subscription.id.to_s].to_f
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
      .where(pay_compcode: @compcode, pay_date: Date.today)
      .sum(:pay_amount).to_f
  end

  # These are used in views — redirect them to cache
  def get_member_detail(id)
    @members_map[id.to_s]
  end

  def get_plan_detail(id)
    @plans_map[id.to_s]
  end

  def latest_subscriptions
    TrnMemberSubscription
      .where(ms_compcode: session[:loggedUserCompCode])
      .joins(<<~SQL)
        INNER JOIN (
          SELECT ms_member_id, MAX(ms_end_date) AS max_end_date
          FROM trn_member_subscriptions
          WHERE ms_compcode='#{session[:loggedUserCompCode]}'
          GROUP BY ms_member_id
        ) latest
        ON latest.ms_member_id = trn_member_subscriptions.ms_member_id
        AND latest.max_end_date = trn_member_subscriptions.ms_end_date
      SQL
  end
end
