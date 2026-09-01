class ChangePasswordController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    def index
        @companyCode   =  session[:loggedUserCompCode]
        isuserid       =  session[:autherizedUserId] 
        userobj        = User.where("id =?",isuserid).first  
        if userobj
            mystatus = userobj.loginfirsttime 
            if mystatus.to_s !='Y'
                userobj.update(:loginfirsttime=>'Y')
            end
        end
  end

  def show

  end

  def create
    usePath       = "#{root_url}"+'change_password'
    isFlags       =  true
    @companyCode  =  session[:loggedUserCompCode]
    isuserid      =  session[:autherizedUserId]
    isPassword    = params[:new_password].to_s.delete(' ')
    oldPassword   = params[:old_password].to_s.delete(' ')

    
    if oldPassword == nil || oldPassword == ''
          isFlags = false
          flash[:error] =  "Old password is required."
    elsif isPassword == nil || isPassword == ''  
          isFlags = false
          flash[:error] =  "New password is required."   
    else
        @isUserdetail =  User.where("usercompcode = ? AND id=?",@companyCode,isuserid).first
        if @isUserdetail
                if !@isUserdetail.authenticate_password(oldPassword)
                    isFlags = false
                    flash[:error] =  "Old password is mismatched."      
                else
                     # Always re-stored as bcrypt, whatever it was before.
                     @isUserdetail.set_password(isPassword)
                     # The session carries a copy of the stored digest and is
                     # re-checked on every request, so refresh it here or the
                     # user is bounced to the login screen mid-session.
                     if session[:logedUserId].to_i == @isUserdetail.id.to_i
                       session[:SECURED_LOGIN_CHK] = @isUserdetail.reload.secured_login_check_value
                     end
                     isFlags       =  true
                     flash[:error] =  "Password changed successfully." 
                end
        end



    end

    if !isFlags       
        session[:isErrorhandled] = 1
     else
        session[:postedpamams]   = nil
        session[:isErrorhandled] = nil
        session.delete(:postedpamams)
        session.delete(:isErrorhandled)
     end
     redirect_to usePath

  end
end
