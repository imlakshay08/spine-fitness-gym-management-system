class LoginController < ApplicationController
 skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process,:search]
	  def index
      
    end   

    ######## PROCESS TO LOGIN ################################
def create
    useUrl =  "#{root_url}"+"login"
     if params[:userName] == ''
        flash[:error] = "Please enter user name"
        redirect_to useUrl
     elsif params[:userPassword] == ''
        flash[:error] =  "Plase enter password"
        redirect_to useUrl
     elsif params[:userName]!='' && params[:userPassword]!=''
        xpassword = Digest::MD5.hexdigest(params[:userPassword])
        @Item     = User.where("username = ? AND userpassword = ?",params[:userName],xpassword).first
        if @Item
          if @Item.usercompcode.to_s == '' || @Item.usercompcode.to_s == nil
            flash[:error] =  "Invalid company,you try to logged in!"
            redirect_to :controller=> :login,:action => :index #,
          elsif @Item.username.to_s == params[:userName] &&  @Item.userpassword.to_s == xpassword
            session[:LOCKED_EXPIRY]  = 'Y'
            session[:LOCKED_EXP_MSG] = nil
            session[:LOCKED_EXP_CNT] = nil
            @lockmessage = nil
            @compcodes   = @Item.usercompcode.to_s
            @alloweduser = false

        
            flash[:error] = nil
            session[:loggedUserCompCode]  = @Item.usercompcode.to_s
            session[:logedUserId]         = @Item.id
            session[:autherizedUserId]    = @Item.id
            session[:autherizedUserName]  = @Item.firstname.to_s
            session[:autherizedUserImage] = @Item.userimage.to_s
            session[:autherizedLoc]       = @Item.userlocation.to_s
            session[:autherizedUserLastNm]= @Item.lastname.to_s
            session[:autherizedUserType]  = @Item.usertype.to_s
            session[:authorizedLoggedId]  = ###@Item.user_custid
            session[:loginUserName]       = @Item.username.to_s
            session[:SECURED_LOGIN_CHK]   = xpassword
            session[:my_selected_users]   = @Item.username.to_s
            session[:facultyId]           = @Item.faculty.to_i

            if @Item.id.to_i >0
              @userUpdateDates = User.where("usercompcode=? and id=?",@compcodes,@Item.id)
              if @userUpdateDates
                Time.zone = "Kolkata"
                usrudate  = Time.zone.now               
                dates4    = usrudate.strftime("%Y-%m-%d %I:%M:%S")
                #@userUpdateDates.update(:updated_at=>dates4)
              end
            end
         
              modulename   = "Login"
              description  = "Login User"
              process_login_log_data("LOGIN",modulename,description)
          
                  
                   redirect_to "#{root_url}"+"dashboard"
      
          end
          else
            flash[:error] =  "User Id or Password mismatched"
            redirect_to useUrl 
          end
       
    end
  
    
     
end
############### END PROCESS LOGIN ##########################
end
