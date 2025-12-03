class LogAuditController < ApplicationController
  before_action :require_login
  before_action :get_user_access_permissions
  skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process,:search]
  helper_method :currency_formatted,:formatted_date,:year_month_days_formatted,:set_dct,:set_ent
  helper_method :user_detail,:get_departments_by_code
 def index
    @compcodes      =  session[:loggedUserCompCode]
    month_number =  Time.now.month
      month_begin  =  Date.new(Date.today.year, month_number)
    begdate      =  Date.parse(month_begin.to_s)
    @nbegindate  =  begdate.strftime('%d-%b-%Y')
    month_ending =  month_begin.end_of_month
    endingdate   =  Date.parse(month_ending.to_s)
    @enddate     =  endingdate.strftime('%d-%b-%Y')
      @UserLogList    = get_user_log_list
 end

 def refresh_log_audit
  session[:req_log_list] = nil
  session[:fromdated] = nil
  session[:uptodated] = nil
  session[:sess_search_login] = nil
  redirect_to "#{root_url}log_audit"
 end
 private
 def get_user_log_list
  if params[:page].to_i > 0
    pages = params[:page]
  else
    pages = 1
  end
  
  if params[:server_request].present? && params[:server_request] != ''
    session[:req_log_list] = nil
    session[:fromdated] = nil
    session[:uptodated] = nil
    session[:sess_search_login] = nil
  end
  
  filter_search = params[:user_search].present? && params[:user_search] != '' ? params[:user_search].to_s.strip : session[:req_log_list].to_s.strip
  search_fromdated = params[:search_fromdated].present? && params[:search_fromdated] != '' ? params[:search_fromdated] : session[:fromdated]
  search_uptodated = params[:search_uptodated].present? && params[:search_uptodated] != '' ? params[:search_uptodated] : session[:uptodated]
  search_login = params[:search_login].present? && params[:search_login] != '' ? params[:search_login] : session[:sess_search_login]
  iswhere = "ad_compcode = '#{@compcodes}'"
  
    if search_login.present? && search_login != ''
    @search_login = search_login
    session[:sess_search_login] = search_login
  end

  if filter_search.present? && filter_search != ''
    iswhere += " AND (ad_user LIKE '%#{filter_search}%' OR ad_event LIKE '%#{filter_search}%')"
    @user_search = filter_search
    session[:req_log_list] = filter_search
  end

  if search_fromdated.present? && search_fromdated != ''
    iswhere += " AND ad_date >= '#{year_month_days_formatted(search_fromdated)}'"
    @search_fromdated = search_fromdated
    session[:fromdated] = search_fromdated
  else
     iswhere += " AND ad_date >= '#{year_month_days_formatted(@nbegindate)}'"
  end

  if search_uptodated.present? && search_uptodated != ''
    iswhere += " AND ad_date <= '#{year_month_days_formatted(search_uptodated)}'"
    @search_uptodated = search_uptodated
    session[:uptodated] = search_uptodated
  else
    iswhere += " AND ad_date <= '#{year_month_days_formatted(@enddate)}'"
  end
   stsobj = []
  if  search_login.present?
    if search_login == "LL"
      stsobj = TrnLoginDatum.where(iswhere).paginate(:page =>pages,:per_page => 50).order(id: :desc)
    else
      stsobj = TrnAuditTrial.where(iswhere).paginate(:page =>pages,:per_page => 50).order(id: :desc)
    end
  end
  return stsobj
end

end
