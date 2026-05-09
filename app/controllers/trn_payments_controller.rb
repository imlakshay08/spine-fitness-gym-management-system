include GlobalCodeGenerator

class TrnPaymentsController < ApplicationController
  before_action :require_login
  before_action :get_user_access_permissions
  skip_before_action :verify_authenticity_token, only: [:index]

  def index
    @compcodes  = session[:loggedUserCompCode]
    @compDetail = MstCompany.where(["cmp_companycode = ?", @compcodes]).first

    # --- Date filter (default: current month) ---
    if params[:from_date].present? && params[:to_date].present?
      @from_date = Date.strptime(params[:from_date], "%d-%b-%Y") rescue Date.today.beginning_of_month
      @to_date   = Date.strptime(params[:to_date],   "%d-%b-%Y") rescue Date.today
    else
      @from_date = Date.today.beginning_of_month
      @to_date   = Date.today
    end

    @filter_plan = params[:filter_plan].to_s.strip
    @filter_mode = params[:filter_mode].to_s.strip

    # --- Load payments in date range ---
    @payments = TrnPayment
                  .where(pay_compcode: @compcodes, pay_ref_type: 'MEMBER_SUBSCRIPTION')
                  .where("pay_date BETWEEN ? AND ?", @from_date, @to_date)
                  .order("pay_date DESC, pay_no ASC")

    # --- Pre-load subscriptions for all payments (one query) ---
    sub_ids = @payments.map(&:pay_ref_id).uniq
    subscriptions = TrnMemberSubscription
                      .where(ms_compcode: @compcodes, id: sub_ids)
                      .to_a
    @subscriptions_map = subscriptions.index_by { |s| s.id.to_s }

    # --- Pre-load members (one query) ---
    member_ids = subscriptions.map(&:ms_member_id).uniq
    @members_map = MstMembersList
                     .where(mmbr_compcode: @compcodes, id: member_ids)
                     .index_by { |m| m.id.to_s }

    # --- Pre-load plans (one query) ---
    plan_ids = subscriptions.map(&:ms_plan_id).uniq
    @plans_map = MstMembershipPlan
                   .where(plan_compcode: @compcodes, id: plan_ids)
                   .index_by { |p| p.id.to_s }

    # --- All plans for filter dropdown ---
    @all_plans = MstMembershipPlan.where(plan_compcode: @compcodes).order("plan_name ASC")

    # --- Apply plan filter if selected ---
    if @filter_plan.present?
      allowed_sub_ids = subscriptions.select { |s| s.ms_plan_id.to_s == @filter_plan }.map { |s| s.id.to_s }
      @payments = @payments.select { |p| allowed_sub_ids.include?(p.pay_ref_id.to_s) }
    else
      @payments = @payments.to_a
    end

    # --- Apply payment mode filter ---
    if @filter_mode.present?
      @payments = @payments.select { |p| p.pay_mode.to_s.downcase == @filter_mode.downcase }
    end

    # --- Summary stats ---
    @total_collected   = @payments.sum { |p| p.pay_amount.to_f }
    @total_cash        = @payments.select { |p| p.pay_mode.to_s.downcase == 'cash' }.sum { |p| p.pay_amount.to_f }
    @total_upi         = @payments.select { |p| p.pay_mode.to_s.downcase == 'upi'  }.sum { |p| p.pay_amount.to_f }
    @total_count       = @payments.count

    # --- Group by plan for plan-wise summary ---
    @plan_wise = {}
    @payments.each do |pay|
      sub  = @subscriptions_map[pay.pay_ref_id.to_s]
      next unless sub
      plan = @plans_map[sub.ms_plan_id.to_s]
      next unless plan
      key  = plan.plan_name
      @plan_wise[key] ||= { count: 0, total: 0.0, plan: plan }
      @plan_wise[key][:count] += 1
      @plan_wise[key][:total] += pay.pay_amount.to_f
    end
  end
end
