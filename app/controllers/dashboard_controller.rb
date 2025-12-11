class DashboardController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct  
    def index
        @stock_list = MstStockList.where(["sl_compcode=?",session[:loggedUserCompCode]])

  @active_subs     = active_subscriptions
  @expiring_subs   = expiring_soon(7)
  @expired_subs    = expired_subscriptions
    end

    def active_subscriptions
  TrnMemberSubscription.where(
    "ms_compcode=? AND ms_end_date >= ?",
    session[:loggedUserCompCode],
    Date.today
  )
end

def expiring_soon(days = 7)
  TrnMemberSubscription.where(
    "ms_compcode=? AND ms_end_date BETWEEN ? AND ?",
    session[:loggedUserCompCode],
    Date.today,
    Date.today + days
  )
end

def expired_subscriptions
  TrnMemberSubscription.where(
    "ms_compcode=? AND ms_end_date < ?",
    session[:loggedUserCompCode],
    Date.today
  )
end

      
end
