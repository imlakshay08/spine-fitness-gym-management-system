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
            noldpassword  = Digest::MD5.hexdigest(oldPassword)
            dbpassword    = @isUserdetail.userpassword
                if noldpassword != dbpassword
                    isFlags = false
                    flash[:error] =  "Old password is mismatched."      
                else
                     newpassword =  Digest::MD5.hexdigest(isPassword) 
                     @isUserdetail.update(:userpassword=>newpassword)
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
