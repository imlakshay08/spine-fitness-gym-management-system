class LogoutController < ApplicationController
def index
useurl = "#{root_url}"+"login"
if session[:logedUserId].present? then
    session[:logedUserId] =nil
    session.delete(:logedUserId)
    session[:isprintableid]        = nil
    session[:isprintablesaletype]  = nil
    session[:specialPermissions]   = nil
    session[:allowed_pages]        = nil
    session[:allowed_pages_retail] = nil
    session[:autherizedUserId]     = nil
    session[:autherizedUserName]   = nil
    session[:autherizedUserImage]  = nil
    session[:autherizedLoc]        = nil
    session[:autherizedUserLastNm] = nil
    session[:autherizedUserType]   = nil
    session[:authorizedGSTNumber]  = nil
    session[:total_customers]      = nil
    session[:loggedUserCompCode]   = nil
    session[:allowed_pages_retail] = nil
    session[:total_pendingcredt]    = nil
    session[:LOCKED_EXP_MSG]        = nil
    session[:LOCKED_EXP_CNT]        = nil
    session[:isErrorhandled]        = nil
    session[:LOCKED_EXPIRY]         = nil
    session[:request_params]        = nil
    session[:isErrorhandled]        = nil
    session[:process_boxno]         = nil
    session[:process_purno]         = nil
    session[:store_detail]          = nil
    session[:req_search_qualific]   = nil
    session[:req_search_state]      = nil
    session[:req_search_district]   = nil
    session[:req_search_city]       = nil
    session[:req_search_departcode] = nil
    session[:req_search_design]     = nil
    session[:req_filters]           = nil
    session[:req_search_qualific]   = nil
    session[:req_search_departcode] = nil
    session[:req_sewadar_code]       = nil
    session[:req_sewadar_name]        = nil
    session[:req_sewadar_designation] = nil
    session[:request_processlogid]    = nil
    session[:req_sewp_cat]            = nil
    session[:swp_sewadar_category]     = nil
    session[:swp_sewa_member]           = nil
    session[:lrequest_sewadar_name]     = nil
    session[:lrequest_leave_code]       = nil
    session[:lrequest_leave_type]       = nil
    session[:lrequest_search_fromdated]  = nil
    session[:lrequest_search_uptodated]  = nil
    session[:lvoucher_department]        = nil
    session[:alrequest_sewadar_name]     = nil
    session[:alvoucher_department]       = nil
    session[:requested_switch_type]      = nil
    session[:switch_menu_name]           = nil
    session[:first_time_login_window]    = nil
    session[:switch_menu]                = nil
    session[:facultyId]                  = nil
      session[:sess_search_login] = nil
 end
redirect_to useurl
end
end
