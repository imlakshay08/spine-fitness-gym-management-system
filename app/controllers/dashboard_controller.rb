class DashboardController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct  
    def index
        @stock_list = MstStockList.where(["sl_compcode=?",session[:loggedUserCompCode]])

    end
      
end
