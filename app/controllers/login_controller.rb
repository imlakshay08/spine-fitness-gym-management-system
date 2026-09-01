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
        # Throttle before touching the database, so a script cannot sit here
        # guessing passwords all night against a 200-member gym's admin login.
        if login_throttled?(params[:userName])
          flash[:error] = "Too many failed attempts. Please wait a minute and try again."
          redirect_to useUrl
          return
        end

        # Look the user up by name only, then verify the password through the
        # model. That covers both the legacy MD5 rows and bcrypt rows, and
        # silently re-stores the password as bcrypt on a successful login.
        attempted = User.find_by(username: params[:userName])
        @Item     = (attempted && attempted.authenticate_and_upgrade(params[:userPassword])) ? attempted : nil

        if @Item
          if @Item.usercompcode.to_s == '' || @Item.usercompcode.to_s == nil
            flash[:error] =  "Invalid company,you try to logged in!"
            redirect_to :controller=> :login,:action => :index #,
          else
            # Issue a brand-new session id now that the identity has changed.
            # Without this, a session id planted before login (session
            # fixation) would still be valid afterwards and would carry the
            # attacker straight into the logged-in account.
            reset_session
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
            session[:SECURED_LOGIN_CHK]   = @Item.secured_login_check_value
            session[:my_selected_users]   = @Item.username.to_s
            session[:facultyId]           = @Item.faculty.to_i

            if @Item.id.to_i >0
              @userUpdateDates = User.where("usercompcode=? and id=?",@compcodes,@Item.id)
              if @userUpdateDates
                # Same leak as ApplicationController had: assigning Time.zone
                # here poisoned every later request served by this thread.
                usrudate  = Time.current.in_time_zone(IST_ZONE)
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
            # Recorded against the attempted account's company when the
            # username exists, so a burst of failures is visible in the audit
            # log rather than only in the server log.
            process_login_log_data("LOGIN FAILED", "Login",
                                   "Failed login for #{params[:userName].to_s.first(40)} from #{request.remote_ip}",
                                   attempted&.usercompcode.to_s)
            flash[:error] =  "User Id or Password mismatched"
            redirect_to useUrl 
          end
       
    end
  
    
     
end
############### END PROCESS LOGIN ##########################

  private

  # Brute-force throttle.
  #
  # Backed by the trn_login_data audit table rather than Rails.cache: the cache
  # is a NullStore in development and resets on every deploy in production, so
  # a cache-backed counter would silently not throttle at all. The audit row is
  # already being written for every attempt, so this costs one small query per
  # login POST and survives restarts.
  #
  # Counted per source IP, and only since that IP's last *successful* login —
  # so a staff member who mistypes a few times and then gets in starts from
  # zero again, and nothing has to be deleted from the audit trail.
  MAX_LOGIN_ATTEMPTS = 8
  LOGIN_BLOCK_WINDOW = 1.minute

  def login_throttled?(_username)
    recent_login_failures >= MAX_LOGIN_ATTEMPTS
  end

  def recent_login_failures
    ip    = request.remote_ip
    since = LOGIN_BLOCK_WINDOW.ago

    last_success = TrnLoginDatum.where(ad_event: 'LOGIN', ad_ip: ip).maximum(:created_at)
    since = last_success if last_success && last_success > since

    TrnLoginDatum
      .where(ad_event: 'LOGIN FAILED', ad_ip: ip)
      .where('created_at >= ?', since)
      .count
  rescue StandardError => e
    # Never let the throttle itself lock staff out of the app.
    Rails.logger.error "[LoginThrottle] could not read failures: #{e.class}: #{e.message}"
    0
  end
end
