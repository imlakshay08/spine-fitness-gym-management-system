class CreateUserController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token, only: [:index,:ajax_process,:search,:create_user,:user_list]
    include ErpModule::Common
    helper_method :currency_formatted,:formatted_date,:year_month_days_formatted,:get_user_global_access_list
 def index
    @compCodes   = session[:loggedUserCompCode]
    # @ListDepart  = MstHeadOffice.where("hof_compcode =?",@compCodes).order("hof_description ASC")
    @ListModule = MstListModule.where("lm_compcode = ? AND lm_status = 'Y'", @compCodes).order("id ASC")
    module_names = []
    if @ListModule.any?
      @ListModule.each do |mod|
        module_names << mod.lm_modules # Collect all module names into an array
      end
    end
    @menus_with_access = MstMenuEntry.where("me_compcode = ? AND me_heading IN (?)", @compCodes, module_names)
    @menus_with_access_grouped = @menus_with_access.group_by(&:me_heading)


    #@selected_user_id = @UserListed ? @UserListed.id : 0
    #@module_code = listmodulecode
    @ListUser  = User.where("usercompcode =?",@compCodes)
    @Faculty        = MstFaculty.where("fclty_compcode =? AND fclty_name != ''  ",@compCodes)
    month_number     =  Time.now.month
    month_begin      =  Date.new(Date.today.year, month_number)
    begdate          =  Date.parse(month_begin.to_s)
    @nbegindate      =  begdate.strftime('%d-%b-%Y')
    month_ending     =  month_begin.end_of_month
    endingDate       =  Date.parse(month_ending.to_s)
    @enddate         =  endingDate.strftime('%d-%b-%Y')	
    # @ListForms   = TrnUserAccess.where("id >0").group("form_type").order("form_type ASC")
    # @useFormList = TrnUserAccess.where("id>0").order("menu_name ASC"
    @ListUsers   = nil
    if params[:id].to_i >0
      @ListUsers    = User.where("usercompcode = ? AND id = ?",@compCodes,params[:id]).first
      if @ListUsers.present?
      @selected_user_id = @ListUsers.id
      end
   
    end

 end
 def ajax_process
   @compCodes = session[:loggedUserCompCode]
  if params[:identity] !=nil && params[:identity] !='' && params[:identity] == 'HDING'
      get_module_heading
       return 
     elsif params[:identity] !=nil && params[:identity] != '' && params[:identity] == 'CHANGESTATUS'
       process_update_user()
     return
     elsif params[:identity] !=nil && params[:identity] != '' && params[:identity] == 'RESET'
       reset_user_password()
     return
      
  end
  
 end
  
  def create
  @compCodes   = session[:loggedUserCompCode]
  isFlags      = true
    begin

    if params[:username] == '' || params[:username] == nil
          flash[:error] =  "User name is required."
          isFlags      =  false
    elsif params[:usertype] == '' || params[:usertype] == nil
          flash[:error] =  "User type is required."
          isFlags      =   false
    	
        
    else
      if params[:phonenumber] !=nil && params[:phonenumber] !=''
        if params[:phonenumber].to_s.length <10
          flash[:error] =  "Mobile number should be 10 digits."
           isFlags = false		
        end
      end
        currentusername = params[:currentusername].to_s.strip
        username        = params[:username].to_s.strip
        mid             = params[:mid]
        newpassowrd     = params[:userpassword].to_s.strip 
        
          if mid.to_i >0
                
                      if currentusername.to_s.delete(' ').downcase != username.to_s.delete(' ').downcase
                          
                          userobj = User.where("username = ?",username)
                          if userobj.length >0
                                flash[:error] = "Your entered username is already taken, Please try to another1."
                                isFlags       = false
                          end
                      end
                  
                  if isFlags
                        userupobj  = User.where("id = ?",mid).first
                          if userupobj
                            myid = userupobj.id
                              userupobj.update(user_params)
                              get_user_access_controll(myid)
                              flash[:error] = "Data updated successfully."
                              isFlags       = true
                              modulename = "Administration"
                              description = "Create User Update: #{params[:username]}"
                              process_request_log_data("UPDATE", modulename, description)
                          end
                  end
                      
            else                   
            
              userobj = User.where("username = ?",username)
                    if userobj.length >0
                          flash[:error] = "Your entered username is already taken, Please try to another."
                          isFlags       = false
                    end

                      if isFlags
                          @usersobj = User.new(user_params)
                          if @usersobj.save                            
                            myid = mid = @usersobj.id.to_i
                            get_user_access_controll(myid)
                            flash[:error] =  "Data saved successfully."
                            isFlags = true
                            modulename = "Administration"
                            description = "Create User Save: #{params[:username]}"
                            process_request_log_data("SAVE", modulename, description)
                        end
                      end
          end
    end

    if !isFlags
        session[:isErrorhandled]    = 1
        session[:req_username]      = params[:username]
      
        session[:req_usertype]      = params[:usertype]
        
    else
        session[:req_username]      = nil
    
        session[:req_usertype]      = nil
        session[:isrequestparam] = nil
        session.delete(:isrequestparam)
        session[:isErrorhandled] = nil
        session.delete(:isErrorhandled)
    end

    rescue Exception => exc
        flash[:error]            = "#{exc.message}"
        session[:isErrorhandled] = 1
    end
    if !isFlags
        redirect_to "#{root_url}"+"create_user"
    else
        redirect_to "#{root_url}"+"create_user/user_list"
    end
    

  end
   def user_list_refresh
   session[:req_search_username] = nil
    redirect_to "#{root_url}create_user/user_list"
 end

 def get_user_access_controll(userid)
  i = 0
  mycreateform = ""
  mymodule         = params[:mymodule_codes]!=nil && params[:mymodule_codes]!='' ? params[:mymodule_codes] : ''
  mymoduledchecked = params[:mymoduledchecked]!=nil && params[:mymoduledchecked]!='' ? params[:mymoduledchecked] : 0
  if params[:ua_formname]!=nil && params[:ua_formname]!=''
  
      params[:ua_formname].each do |userforms|
        mycreateform = ""
        formname     = ""
        subheading   = ""
        actionname   = ""
            if params[:ua_formname][i] !=nil && params[:ua_formname][i] !=''
             
                  formname       = params[:ua_formname][i] ? params[:ua_formname][i].to_s.strip : ''
                  module_code    = params[:ua_module_code][i] ? params[:ua_module_code][i].to_s.strip : ''
                  subheading     = params[:ua_subheading][i] ? params[:ua_subheading][i].to_s.strip : ''
                  actionname     = params[:ua_actionname][i] ? params[:ua_actionname][i].to_s.strip : ''
                  ua_combine_name= params[:ua_combine_name][i] ? params[:ua_combine_name][i].to_s.strip : ''
                   #checkstatus  =   params[:ua_action][formname][i] !=nil && params[:ua_action][formname][i] !='' ?  params[:ua_action][formname][i] : nil
                  if  params[:ua_action] && params[:ua_action][ua_combine_name]
                      params[:ua_action][ua_combine_name].each do |actval|
                          if actval !=nil && actval !=''
                            mycreateform +=actval.to_s+","
                          end
  
                      end
                  end 
                
            else
                   formname = ''
            end                  
           
            if mycreateform !=nil && mycreateform !=''
              mycreateform = mycreateform.to_s.chop
              mycreateforms = mycreateform.to_s.split(",")
              arrunq        = mycreateforms.to_a.uniq
              mycreateform  = arrunq.to_a.join(",")
              
            end
           
            if mymodule!=nil && mymodule!=''             
                cerate_user_access_form(userid,formname,mycreateform,module_code,subheading,actionname)               
               # process_update_user_module(userid,mycreateform,mymodule,mymoduledchecked)
            end
          
            i +=1
       end
    
   end 
 end

    def cerate_user_access_form(userid,formname,myactions,headername="",subheading,actionname)
    compCodes  =  session[:loggedUserCompCode]    
    if actionname!=nil && actionname!=''
       formnames = formname.to_s+"/"+actionname.to_s
    else
       formnames  = formname
    end
    iswhere    = "ua_compcode='#{compCodes}' AND ua_userid='#{userid}' AND UPPER(ua_subheading)=UPPER('#{subheading}') AND UPPER(ua_formname)=UPPER('#{formnames}') AND UPPER(ua_heading)=UPPER('#{headername}')"
    accesobj   = TrnUserAccess.where(iswhere)
    if accesobj.present?
      if myactions.present?
        accesobj.update_all(:ua_action => myactions)
      else
        accesobj.destroy_all
      end
    else
      if myactions.present?
        savebj = TrnUserAccess.new(
          ua_userid: userid,
          ua_compcode: compCodes,
          ua_formname: formnames,
          ua_action: myactions,
          ua_heading: headername,
          ua_subheading: subheading
        )
        if savebj.save
          # Execute message if required
        end
      end
    end
    

    end

# Update user's module list if necessary
def process_update_user_module(userid,permvalue,modules,mymoduledchecked)
  
  if mymoduledchecked.to_i<=0 
         userobjs = User.where("id=?",userid).first
         if  userobjs
             usemodule    = userobjs.listmodule.to_s.split(",")
             newmodulearr = usemodule ? usemodule.delete_if { |i| i.to_s == modules.to_s } : ''
             if newmodulearr.length>0
               newmodulearr  = newmodulearr.join(",")
             else
               newmodulearr=""
             end
             userobjs.update(:listmodule=>newmodulearr)
         end
   end
end
 def destroy
    @compcodes = session[:loggedUserCompCode]
    if params[:id].to_i >0
         @ListUser =  User.where("usercompcode =? AND id = ?",@compcodes,params[:id]).first
         if @ListUser
              @ListUser.destroy
              flash[:error] =  "Data deleted successfully."
              isFlags       = true
              session[:isErrorhandled] = 1
         end
    end
    redirect_to "#{root_url}create_user/user_list"
 end
 def user_list
    @compCodes    = session[:loggedUserCompCode]
     iswhere       = "username <>'' "
     if params[:requestserver] !=nil && params[:requestserver] !=''
       session[:req_search_username] = nil
     end
     search_username   = params[:search_username] !=nil && params[:search_username] !='' ? params[:search_username] : session[:req_search_username]
    
     if search_username !=nil && search_username !=''
        iswhere       += " AND username LIKE '%#{search_username}%'"
        session[:req_search_username] = search_username
        @search_username = search_username
     end
     if params[:page].to_i >0
        pages = params[:page]
        else
        pages = 1
        end
       @AllUsers    = User.where(iswhere).paginate(:page =>pages,:per_page => 10).order("id asc")
end

private
def process_update_user
  compcodes = session[:loggedUserCompCode]
  userid = params[:userid]
  userstatus = params[:userstatus]
  status = false
  actionobj = User.find_by(usercompcode: compcodes, id: userid)

  if actionobj
    if actionobj.userstatus == 'Y'
      actionobj.update(userstatus: 'N')
      flash[:error] =  "User Deactivated successfully."
      status = 'I'  # Add the new user status 'I' to the status variable
      # modulename = "Admin Tools"
      # description = "User Deactivated: #{params[:userid]}"
      # process_request_log_data("DEACTIVATED", modulename, description)
    elsif actionobj.userstatus == 'N'
      actionobj.update(userstatus: 'Y')
      flash[:error] =  "User Activated successfully."
      status = 'Y'  # Add the new user status 'Y' to the status variable
      # modulename = "Admin Tools"
      # description = "User Activated: #{params[:userid]}"
      # process_request_log_data("ACTIVATED", modulename, description)
    end
   
  end
  respond_to do |format|
    format.json { render json: { status: status } }
  end
end
def reset_user_password
  compcodes = session[:loggedUserCompCode]
  userid    = params[:reqid]
  new_pass  = params[:new_pass]

  @isUserdetail = User.where("usercompcode = ? AND id = ?", compcodes, userid).first

  if @isUserdetail
    if new_pass 
      newpassword = Digest::MD5.hexdigest(new_pass)
      @isUserdetail.update(userpassword: newpassword)
      isFlags = true
      message = "Password changed successfully."
      # modulename = "Admin Tools"
      # description = "Password Reset: #{params[:reqid]}"
      # process_request_log_data("RESET PASSWORD", modulename, description)
    end
  else
    isFlags = false
    message = "User not found."  # You might want to handle the case when the user is not found.
  end

  respond_to do |format|
    format.json { render json: { 'data' => '', 'message' => message, :status => isFlags } }
  end
end

private
def user_params
    compcode              = session[:loggedUserCompCode]
    params[:usercompcode] = compcode
    params[:userimage]    = ""
    mid                   = params[:mid] 
    params[:username]     =  params[:username] !=nil &&  params[:username] !='' ?  params[:username] : ''
    userpassword          =  params[:userpassword] !=nil &&  params[:userpassword] !='' ?  params[:userpassword] : ''
    params[:usertype]     =  params[:usertype] !=nil &&  params[:usertype] !='' ?  params[:usertype] : ''
    params[:userdate]     =  params[:userdate] !=nil &&  params[:userdate] !='' ?  params[:userdate] : ''
    params[:phonenumber]  = params[:phonenumber] !=nil && params[:phonenumber]!=''? params[:phonenumber] : ''
    params[:listmodule]   =  params[:mymodule_codes]!=nil && params[:mymodule_codes]!='' ? params[:mymodule_codes] : ''
    params[:spspermission] = ''
    params[:product_prefix] = ''
    params[:product_length] = 0

      xpassword = nil
      if userpassword !='' && userpassword !=nil
        xpassword = Digest::MD5.hexdigest(userpassword)
        params[:userpassword] = xpassword
      end
      if mid.to_i >0
        assignedmodule = user_detail(mid)
        if assignedmodule
            listmodule =listmodule.to_s+","+ assignedmodule.listmodule.to_s

        end

        if listmodule !=nil && listmodule!=''
          listmodules = listmodule.to_s.split(",")
          narr       = listmodules.uniq
          listmodule = narr.to_a.join(",")
        end
    end
       if mid.to_i >0
            if xpassword != nil && xpassword != ''
               params.permit(:usercompcode,:userlocation,:username,:firstname,:userpassword,:usertype,:userimage,:phonenumber,:userdate,:faculty,:listmodule)
            else
              params.permit(:usercompcode,:userlocation,:username,:firstname,:usertype,:userimage,:phonenumber,:userdate,:faculty,:listmodule)
            end

       else
             params.permit(:usercompcode,:userlocation,:username,:firstname,:userpassword,:usertype,:userimage,:phonenumber,:userdate,:faculty,:listmodule)
       end

 end

def get_user_global_access_list(userid,formname,headname="",actionname="",subheading="")
  compCodes  =  session[:loggedUserCompCode]
    if actionname!=nil && actionname!=''
       formnames = formname.to_s+"/"+actionname.to_s
    else
       formnames  = formname
    end       
  iswhere    = "ua_compcode='#{compCodes}' AND ua_userid='#{userid}' AND UPPER(ua_formname)=UPPER('#{formnames}') AND UPPER(ua_heading)=UPPER('#{headname}') AND UPPER(ua_subheading)=UPPER('#{subheading}')"
  accesobj   = TrnUserAccess.where(iswhere).first
  return accesobj
end
 private
 def get_module_headings(module_name)
  company_code = session[:loggedUserCompCode]
  module_headings = []
  unique_headings = []

  # Construct the query condition
  query_condition = "me_compcode='#{company_code}' AND me_heading LIKE '%#{module_name.to_s}%'"

  # Fetch distinct menu entries based on the query condition
  menu_entries = MstMenuEntry.where(query_condition).group("me_menuname").order("me_menubar ASC")

  if menu_entries.any?
    menu_entries.each do |entry|
      if entry.me_menubar.present?
        module_headings.push(entry.me_menubar)
      else
        module_headings.push(entry.id)
      end
    end

    # Get unique module headings
    unique_headings = module_headings.uniq if module_headings.any?
  end

  return unique_headings
end


end
