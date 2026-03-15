class ApplicationController < ActionController::Base
   protect_from_forgery with: :exception
   rescue_from ActiveRecord::RecordNotFound, :with => :render_404
   include ErpModule::Common
   helper_method :get_dob_calculate,:page_linked,:set_ent,:set_dct,:formatted_date,:get_student_personal_information,:get_latest_subscription,:get_all_family_information,:get_faculty_detail,:get_club_detail,:get_timetable_information,:get_course_detail,:get_current_stock,:get_plan_detail,:get_stock_detail,:get_member_detail,:get_all_member_detail,:get_staff_detail,:get_attendance_info,:generate_common_numbers
  
   def serial_global_number(lgth)
     chracters = ""
    for i in 1..lgth
        chracters +="0"
    end
    return chracters
   end
   private
   def process_request_log_data(event,modulename,description,compcode="")
       compcodes  = compcode !=nil && compcode !=''? compcode : session[:loggedUserCompCode]
       #originlpth = request.fullpath;
       originlpth = "#{request.scheme}://#{request.host}:#{request.port}#{request.fullpath}"
       ipaddress  = request.ip
       deviceid   = request.user_agent
       userid     = session[:autherizedUserId]
       cdate      = get_local_dated()
       ctime      = get_local_time() 
       if event !=nil && event!='' && description!=nil && description!='' && modulename!=nil && modulename!=''
         trnsobj  = TrnAuditTrial.new(:ad_compcode=>compcodes,:ad_event=>event,:ad_module=>modulename,:ad_description=>description,:ad_date=>cdate,:ad_time=>ctime,:ad_user=>userid,:ad_ip=>ipaddress,:ad_device_id=>deviceid,:ad_path=>originlpth)
         if trnsobj.save
           ###########
         end
      end
   end
  
   private
   def process_login_log_data(event,modulename,description,compcode="")
       compcodes  = compcode !=nil && compcode !=''? compcode : session[:loggedUserCompCode]
       #originlpth = request.fullpath;
       originlpth = "#{request.scheme}://#{request.host}:#{request.port}#{request.fullpath}"
       ipaddress  = request.ip
       deviceid   = request.user_agent
       userid     = session[:autherizedUserId]
       cdate      = get_local_dated()
       ctime      = get_local_time() 
       if event !=nil && event!='' && description!=nil && description!='' && modulename!=nil && modulename!=''
         trnsobj  = TrnLoginDatum.new(:ad_compcode=>compcodes,:ad_event=>event,:ad_module=>modulename,:ad_description=>description,:ad_date=>cdate,:ad_time=>ctime,:ad_user=>userid,:ad_ip=>ipaddress,:ad_device_id=>deviceid,:ad_path=>originlpth)
         if trnsobj.save
           ###########
         end
      end
   end
 private
  def require_login
      @securedlogged = false
      current_user
      menu_access_allowed();
      global_user_access_list();
      if !@securedlogged
        redirect_to :controller=> :login
      end
  end
   private
   def get_all_family_information(compcode,regsitratino)
          sewdarobj =  MstStdntFamily.where("stdnt_fam_compcode =? AND stdnt_fam_code =?",compcode,regsitratino)
          return sewdarobj
   end
   private
   def get_all_fee_information(compcode, year, course, currency, semester)
          sewdarobj =  MstFeeList.where("fee_compcode = ? AND fee_year = ? AND fee_crse = ? AND fee_currncy=? AND fee_sem=?", compcode, year, course, currency, semester)
          return sewdarobj
   end
   private
   def get_special_attendnc_information(compcode, date, faculty, course, house, semester)
          sewdarobj =  TrnSpecialAttendance.where("sp_att_compcode = ? AND sp_att_date =? AND sp_att_fclty = ? AND sp_att_crse = ?  AND sp_att_house = ? AND sp_att_sem=?", compcode, date, faculty, course, house, semester)
          return sewdarobj
   end
   private
   def get_general_information(compcode,sewcode)
      sewdarobj =  MstStdntGenDtl.where("stdnt_gn_compcode =? AND stdnt_gn_code =?",compcode,sewcode).first
      return sewdarobj
   end
    private
    def get_family_information(compcode,empcode)
           sewdarobj =  MstStdntFamily.where("stdnt_fam_compcode  =? AND stdnt_fam_code =?",compcode,empcode)
       return sewdarobj
    end
    private
    def get_personal_information(compcode,empcode)
           sewdarobj =  MstStudentDtl.where("stdnt_dtl_compcode =? AND stdnt_dtl_code =?",compcode,empcode).first
           return sewdarobj
    end
    private
    def get_student_personal_information(stdcode)
     @compcodes = session[:loggedUserCompCode]
     stdobj =  MstStudent.where("stdnt_compcode =? AND stdnt_reg_no =?",@compcodes,stdcode).first
     return stdobj
    end

   private
   def get_timetable_information(compcode,year,subject=0,group)
     sewdarobj =  MstTimeTable.where("tt_compcode =? AND tt_year =? AND tt_subject = ? AND tt_group = ?",compcode,year,subject,group)
     return sewdarobj
   end

   private
   def get_group_timetable_information(compcode,year,course,semester)
     sewdarobj =  MstTimeTable.where("tt_compcode =? AND tt_year =? AND tt_course = ? AND tt_semester =?",compcode,year,course,semester)
     return sewdarobj
   end

   private
   def get_faculty_timetable_information(compcode,year,faculty)
     sewdarobj =  MstTimeTable.where("tt_compcode =? AND tt_year =? AND tt_faculty = ?",compcode,year,faculty)
     return sewdarobj
   end
   private
   def get_feelist_search(compcode,year,course)
     sewdarobj =  MstFeeList.where("fee_compcode =? AND fee_year =? AND fee_crse = ? ",compcode,year,course)
     return sewdarobj
   end
   private
   def get_attendance_info(compcode,code)
          sewdarobj =  TrnAttendance.where("att_compcode =? AND att_stdnt_code =?",compcode,code)
          return sewdarobj
   end

  private
  def get_local_dated()
     Time.zone        = "Kolkata"
     lcdate           = Time.zone.now.strftime('%Y-%m-%d')
     return lcdate     
  end
  private
  def get_local_time()
     Time.zone        = "Kolkata"
     lctime           = Time.zone.now.strftime('%I:%M%p')
     return lctime     
  end
  def get_user_list(regid)
    userobj = User.where("id=?",regid).first
     return userobj
  end
     
     private
     def get_course_detail(coursid)
          compcode =  session[:loggedUserCompCode]
          courseobj =  MstCourseList.where("crse_compcode= ? AND id = ?",compcode,coursid).first
          return courseobj
     end

     private
     def get_stock_detail(stockid)
          compcode =  session[:loggedUserCompCode]
          stockobj =  MstStockList.where("sl_compcode= ? AND id = ?",compcode,stockid).first
          return stockobj
     end

     private
     def get_plan_detail(planid)
          compcode =  session[:loggedUserCompCode]
          planobj =  MstMembershipPlan.where("plan_compcode= ? AND id = ?",compcode,planid).first
          return planobj
     end

     private
     def get_member_detail(memberid)
          compcode =  session[:loggedUserCompCode]
          memberobj =  MstMembersList.where("mmbr_compcode= ? AND id = ?",compcode,memberid).first
          return memberobj
     end

     private
     def get_all_member_detail(memberid)
          compcode =  session[:loggedUserCompCode]
          memberobj =  MstMembersList.where("mmbr_compcode= ? AND id = ?",compcode,memberid)
          return memberobj
     end

     private
     def get_staff_detail(staffid)
          compcode =  session[:loggedUserCompCode]
          staffobj =  MstStaffList.where("stf_compcode= ? AND id = ?",compcode,staffid).first
          return staffobj
     end

     private
     def get_current_stock(stock_id)
          compcode = session[:loggedUserCompCode]

          ins  = TrnStockInventory.where("si_compcode=? AND si_stock_id=? AND si_trans_type='IN'", compcode, stock_id).sum(:si_quantity)
          outs = TrnStockInventory.where("si_compcode=? AND si_stock_id=? AND si_trans_type='OUT'", compcode, stock_id).sum(:si_quantity)

          return ins.to_i - outs.to_i
     end

     private
     def get_latest_subscription(member_id)
        TrnMemberSubscription.where("ms_compcode=? AND ms_member_id=?", session[:loggedUserCompCode], member_id)
            .order("ms_end_date DESC").first
    end

    def get_filtered_cities
        MstCity.where(id: @city_id).order("City ASC")
      end
      
  private
   def formatted_date(dates)
        newdate = ''
        if dates!=nil && dates!=''
             dts    = Date.parse(dates.to_s)
             newdate = dts.strftime("%d-%b-%Y")
        end
        return newdate
   end

   private
   def year_month_days_formatted(dates)
        newdate = ''
        if dates!=nil && dates!=''
             dts    = Date.parse(dates.to_s)
             newdate = dts.strftime("%Y-%m-%d")
        end
        return newdate
   end

 def checked_permissioned
      checktotl = check_total_stock_purchased()
     if session[:requestsubmited_data].to_s.blank?
          redirect_to "#{root_url}"
     elsif checktotl.to_f>50
          redirect_to "#{root_url}"          
     end

  end

  def check_scanoutlet
     if session[:request_scanoulet].to_s.blank?
          redirect_to "#{root_url}login"  
     end

  end
  def calculated_points_based(type)
     mypoints = 0
     if( type.to_s == 'CT')
          mypoints = 1.6666    
     elsif( type.to_s == 'QZ')
          mypoints = 6.6666   
     elsif( type.to_s == 'CD')
          mypoints =  3.0769   
     end
     return mypoints
end

def check_total_stock_purchased
        checkstock  =  0
        requestid   =  session[:request_scanoulet]
        if requestid.to_i >0 
            dailyobjs   = TrnDailyEntry.select("SUM(de_stick_purch) as tstick").where(["de_retailercode=? AND de_dated=DATE(NOW())",requestid]).first
            if dailyobjs
                checkstock = dailyobjs.tstick                         
            end
           
       end
      return checkstock
        
    end
    
def check_global_date_difference(start_date, end_date,lwm=0,status="")
     if lwm.to_i >0 
         end_date = end_date.to_date-lwm.to_i
     end
     end_date     = end_date.to_date+1
     start_date1  = Date.parse(start_date.to_s)
     end_date1    = Date.parse(end_date.to_s)
     years        = end_date1.year - start_date1.year
     months       = end_date1.month - start_date1.month
     days         = end_date1.day - start_date1.day
    
     # Adjust months and years if days overflow
     if days < 0
     # Borrow from months
     months -= 1
     last_month = (end_date1 << 1).month
     days += Date.new(end_date1.year, last_month, -1).day
   end
 
     if months < 0
       years -= 1
       months += 12
     end
     if years.to_i==1
         newyear = years.to_s+" Year"
     elsif years.to_i>1
         newyear = years.to_s+" Years"
     end
     if months.to_i == 1
         newmonth = months.to_s+" Month"
     elsif months.to_i>1
         newmonth = months.to_s+" Months"
     end
     if days.to_i == 1
         mydays = days.to_s+" Day"
     elsif days.to_i>1
         mydays = days.to_s+" Days"
     end
     newdays = days
     if days.to_i >0 && months.to_i >0 && years.to_i >0
         messages =  [newyear,newmonth,mydays].compact.join(', ')
     elsif months.to_i >0 && years.to_i >0    
         messages =  [newyear,newmonth,"0 Day"].compact.join(', ')
     elsif newdays.to_i >0 && months.to_i >0 
         messages =  ["0 Year",newmonth,mydays].compact.join(', ')  
     elsif newdays.to_i >0 && years.to_i >0  
         messages =  [newyear,"0 Month",mydays].compact.join(', ')   
     elsif years.to_i >0    
         messages =  [newyear,"0 Month","0 Day"].compact.join(', ')
    elsif months.to_i >0    
         messages =  ["0 Year",newmonth,"0 Day"].compact.join(', ') 
    elsif newdays.to_i >0    
         messages =  ["0 Year","0 Month",mydays].compact.join(', ')        
    end
    return messages
 
   end
   private
 def get_user_access_permissions
   @UserAccessListed = menu_access_allowed();
   global_user_access_list();
 end
 
 def global_email_configs_mail
      @globalEmail = {
  :host   => "smtp.gmail.com",
  :port      => 587,
  :username => "info.inquisitorinfosoft@gmail.com",
  :password  => "fsbxrkspkyexgrnu",
  :domain    => "gmail.com"
}
     
 end
  def current_user
   compcode =  session[:loggedUserCompCode]
   secured_login_passd = session[:SECURED_LOGIN_CHK]!=nil && session[:SECURED_LOGIN_CHK]!='' ? session[:SECURED_LOGIN_CHK] : nil
   isloggeduserid      = session[:logedUserId]!=nil && session[:logedUserId]!='' ? session[:logedUserId] : 0
   
   global_email_configs_mail()

   @ListGlobalModule    = MstListModule.where("lm_compcode = ? AND lm_status='Y'",compcode).order("lm_modules ASC")
   get_user_access_permissions()
   if isloggeduserid
       curr_user  = User.where("id=?",isloggeduserid)
       if curr_user.length >0
           dbpassword =   curr_user[0].userpassword
            if secured_login_passd!=nil && secured_login_passd!='' && dbpassword !=nil && dbpassword!='' && dbpassword == secured_login_passd
              @securedlogged = true
            end
       end
   end
 end
 def escape_data_string(mystr,type="")
     mystring = ""
     if mystr !=nil && mystr !=''
         mystring  = mystr.to_s.strip
     end
     if mystring == '' || mystring == nil
         if type !=nil && type!=''
             if type == 'DT' || 'NB'
                 mystring = 0 
             end
         end
     end
     return mystring
 end
 def get_directory_monthyear
     Time.zone = "Kolkata"
      dirc     = Time.zone.now.strftime("%b").to_s+"-"+Time.zone.now.strftime("%Y").to_s    
     return dirc
 end
 
 def check_validate_date(dates)
      mycounts = 0
     formats = ['%d-%b-%Y','%d-%m-%Y','%d/%m/%Y','%d/%b/%Y']
     formats.each do |format|
          begin
            if Date.strptime(dates, format)
               mycounts = 0
            end
          rescue
               mycounts +=1
          end
     end
     return mycounts
 end
 private
def generate_common_numbers(len)
    nwmbers = ""
    nwmbers = rand(999999).to_s.center(6, rand(len).to_s).to_i
    return nwmbers
end

private
def generate_new_common_numbers(len)
    nwmbers = ""
    nwmbers = rand(9999).to_s.center(4, rand(len).to_s).to_i
    return nwmbers
end
 def get_global_users(isloggeduserid)
     usrobj  = User.where("id=? AND userstatus='Y'",isloggeduserid).first
     return usrobj;
 end

 def get_month_formatts(months)
     newmonths = ""
     if months.to_s.length <9
     newmonths = '0'+ months.to_s
     end
     return newmonths
 end

def get_number_month_data(months)
     monthsstr = 0
     if  months.to_s == "January"
          monthsstr = 1
     elsif  months.to_s == "February"
          monthsstr = 2
     elsif  months.to_s == "March"
          monthsstr = 3
     elsif  months.to_s == "April"
          monthsstr = 4
     elsif  months.to_s == "May"
          monthsstr = 5
     elsif  months.to_s == "June"
          monthsstr = 6
     elsif  months.to_s == "July"
          monthsstr = 7
     elsif  months.to_s == "August"
          monthsstr = 8
     elsif  months.to_s == "September"
          monthsstr = 9
     elsif  months.to_s == "October"
          monthsstr = 10
     elsif  months.to_s == "November"
          monthsstr = 11
     elsif  months.to_s == "December"
          monthsstr = 12
     end
     return monthsstr

end

def get_month_listed_data(months)
     monthsstr = ""
     if  months.to_i == 1
          monthsstr = "January"
     elsif  months.to_i == 2
          monthsstr = "February"
     elsif  months.to_i == 3
          monthsstr = "March"
     elsif  months.to_i == 4
          monthsstr = "April"
     elsif  months.to_i == 5
          monthsstr = "May"
     elsif  months.to_i == 6
          monthsstr = "June"
     elsif  months.to_i == 7
          monthsstr = "July"
     elsif  months.to_i == 8
          monthsstr = "August"
     elsif  months.to_i == 9
          monthsstr = "September"
     elsif  months.to_i == 10
          monthsstr = "October"
     elsif  months.to_i == 11
          monthsstr = "November"
     elsif  months.to_i == 12
          monthsstr = "December"
     end
     return monthsstr

end
def get_total_days_of_month(months,years)
     monthsstr = 0
     if  months.to_i == 1
          monthsstr = 31
     elsif  months.to_i == 2
          ### check leap years
          if years.to_i >0
              if years.to_i%4 == 0
                 monthsstr = 29
              else
                 monthsstr = 28
              end
          else
               monthsstr = 28
          end
     elsif  months.to_i == 3
          monthsstr = 31
     elsif  months.to_i == 4
          monthsstr = 30
     elsif  months.to_i == 5
          monthsstr = 31
     elsif  months.to_i == 6
          monthsstr = 30
     elsif  months.to_i == 7
          monthsstr = 31
     elsif  months.to_i == 8
          monthsstr = 31
     elsif  months.to_i == 9
          monthsstr = 30
     elsif  months.to_i == 10
          monthsstr = 31
     elsif  months.to_i == 11
          monthsstr = 30
     elsif  months.to_i == 12
          monthsstr = 31
     end
    return monthsstr

end


private
def user_detail(id)
    compcode = session[:loggedUserCompCode]
    userobj  = User.where("usercompcode = ? AND id = ?",compcode,id).first
    return userobj
end


private
def get_department_detail(dscode)
    compcode =  session[:loggedUserCompCode]
    disobj   =  Department.where("compCode= ? AND departCode = ? AND subdepartment=''",compcode,dscode).first
    return disobj
end

private
def get_all_department_detail(dscode)
    compcode =  session[:loggedUserCompCode]
    disobj   =  Department.where("compCode = ? AND departCode = ? AND subdepartment=''",compcode,dscode).first
    return disobj
end

 
  private
  def page_linked
    return self.controller_name
  end

  private
  def _random_string_(len)
    charset = %w{ 2 3 4 6 7 9 A C D E F G H J K M N P Q R T V W X Y Z}
    newpasswor = (0...len).map{ charset.to_a[rand(charset.size)] }.join
    return newpasswor
  end

 ######### Check Location Process########
private
def is_allowed_location
  set_cache_headers
  iscompcode    =  session[:loggedUserCompCode]
  @isLogedId    =  session[:autherizedUserId]
  @isLoc        =  session[:autherizedLoc]
  userloggedtp  =  session[:autherizedUserType]
  
  ############# RAW Material############
end

private
def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
end

  private
  def process_files(attfile,currfile,cdirect)
    file_names     =  attfile.original_filename  if  ( attfile !='' && attfile !=nil )
    files          =  attfile.read
    file_types     =  file_names.split('.').last
    new_name_files =  Time.now.to_i
    new_file_name  = "#{new_name_files}." + file_types
    paths1         = Rails.root.join "public", "images", cdirect
    #### Delete Origins#############
    if attfile != '' && attfile!= nil
         if currfile != '' && currfile != nil
           curpath = Rails.root.join "public", "images", cdirect,currfile
           process_unlinks_the_files(curpath)
         end
    end
    ######### Upload here ######################
    File.open("#{paths1}/" + new_file_name, "wb")  do |f|
       f.write(files)
    end
    #corp_image_size_signs
    return new_file_name
  end

  private
  def process_unlinks_the_files(path_to_file)
      File.delete(path_to_file) if File.exist?(path_to_file)
  end


  private
  def global_compcode
      myjsoncompcode = "NMN"
      return myjsoncompcode
  end 
  
  def check_existing_master(type,id)
     checkstk = false
     if type.to_s == 'CITY'
          chkgrpobj   = Transactionmaster.where("Ref_city_id=?",id)
          if chkgrpobj.length >0
               checkstk = true    
          end
     elsif type.to_s == 'WD'
          chkgrpobj   = Transactionmaster.where("Ref_Wd_Id=?",id)
          if chkgrpobj.length >0
               checkstk = true    
          end
     elsif type.to_s == 'ACT'
          chkgrpobj   = Transactionmaster.where("Ref_Activity_id=?",id)
          if chkgrpobj.length >0
               checkstk = true    
          end
     elsif type.to_s == 'BRD'
          chkgrpobj   = Transactionmaster.where("Ref_Brand_id=?",id)
          if chkgrpobj.length >0
               checkstk = true    
          end
     end
     return checkstk 
  end


  private
    def process_files_pos(attfile, currfile, cdirect)
      compcodex     = session[:loggedUserCompCode].to_s.present? ? session[:loggedUserCompCode] : "IHM"
      new_file_name = nil    
     if attfile.present?
     #if params[:mid].to_i > 0 && currfile.to_s.present?
            #Delete the existing file before processing the new one
             #storage_path = "#{compcodex}/#{cdirect}"
            #bunny_delete_storage_file(currfile, storage_path)
           #end

          if attfile.start_with?("data:image/")
               
               # Handle Base64 encoded image
               base64_image = attfile.split(",").last
               image_data   = Base64.decode64(base64_image)
               file_type    = attfile.match(/data:image\/(.*?);/)[1]
               new_file_name = "#{Time.now.to_i}.#{file_type}"
               storage_path  = "#{compcodex}/#{cdirect}"
               begin
                    # Code that might raise an error
                    responses = process_storage_to_bunny(new_file_name, image_data, storage_path) 
                    if responses
                         
                         return new_file_name                                              
                    end  
                    rescue => e
                         new_file_name =  "Error: #{e.message}"
                         # # Handling the error
                         # new_file_name =  "Error: #{e.message}"
                         # return new_file_name

                    end
                 
              
          end
     end
    

    end


    private
    def process_without_base64_files(attfile, currfile, cdirect)
      compcodex     = session[:loggedUserCompCode].to_s.present? ? session[:loggedUserCompCode] : "IHM"
      new_file_name = ''
     if attfile.present?
     
               file_name     =  attfile.original_filename  if  ( attfile !='')
               files          =  attfile.read
               file_type     =  file_name.split('.').last
               ext_file      =  Time.now.to_i    
               new_file_name =  "#{ext_file}." + file_type                           
               storagepath  = "#{compcodex}/#{cdirect}"
               
               # Upload to Bunny.net                                 
               responses = process_storage_to_bunny(new_file_name, files, storagepath) 
               if responses && responses["HttpCode"] == 201
                    return new_file_name   
               end             
                         
                    
     end
     return new_file_name
    end

    
    ########BUNY CONNECTION FILE ##########

  def process_storage_to_bunny(file_name, file_content,storage_zone)
     base_uri     = 'storage.bunnycdn.com'
     access_key   = '52525a0c-43cc-4681-bed88fbebfa6-34f3-462d'
     url          = "#{base_uri}/ihm-inqerp/#{storage_zone}/#{file_name}"
     headers = {
       'AccessKey' => access_key,
       'Accept' => 'application/json',
       'Content-Type' => 'application/octet-stream'
     }
     responses =  RestClient.put(url, file_content, headers)
     return responses
       
   end
   def bunny_delete_storage_file(file_name,storage_zone)
      base_uri     = 'storage.bunnycdn.com'
      access_key   = '52525a0c-43cc-4681-bed88fbebfa6-34f3-462d'
      url          = "#{base_uri}/ihm-inqerp/#{storage_zone}/#{file_name}"
     headers = {
       'AccessKey' => access_key,
       'Accept' => 'application/json',
       'Content-Type' => 'application/octet-stream'
     }
     responses =  RestClient.delete(url,headers)
     return responses
       
   end
  
  ########## END BUNY CONNECTION FILE #########

   ######## START USER ACCESS MODULE DATA ###########
   #### USE for inside of contoller ###########
   def global_user_access_list
     @myAddAld           = false
     @myEditAld          = false
     @myDeletAld         = false
     @myPrintAld         = false
     @myViewAld          = false
     @myCancelAld        = false
     @myApproveald       = false
     controllername      = self.controller_name
     acionnameselected   = self.action_name
     isloggeduserid   = session[:logedUserId]!=nil && session[:logedUserId]!='' ? session[:logedUserId] : 0
     compCodes        = session[:loggedUserCompCode]
     tnsbs            = TrnUserAccess.where("ua_compcode =? AND ua_userid =? AND ua_formname ='#{controllername}'",compCodes,isloggeduserid).first
     if tnsbs.present?
               if tnsbs.ua_action!=nil && tnsbs.ua_action !=''
                   newrights = tnsbs.ua_action.to_s.split(",")
                   if newrights.to_s.include?("AD")
                   @myAddAld = true
                   end
                   if newrights.to_s.include?("ED")
                   @myEditAld = true
                   end
                   if newrights.to_s.include?("DL")
                   @myDeletAld = true
                   end
                   if newrights.to_s.include?("PR")
                   @myPrintAld = true
                   end
                   if newrights.to_s.include?("CL")
                   @myCancelAld = true
                   end
                   if newrights.to_s.include?("VW")
                   @myViewAld = true
                   end
                   @onlyViewSelected = @myViewAld && !@myAddAld && !@myEditAld && !@myDeletAld && !@myPrintAld && !@myCancelAld

               end

     end
 end
  def menu_access_allowed     
   @student       = 0
   @std_list       = 0
   @std_i_card     = 0
   @std_trans_list     = 0
   @std_import=0
   @fee = 0
   @fee_comp_list = 0
   @fees_list = 0
   @time    = 0
   @time_create = 0
   @time_date = 0
   @fac = 0
   @fac_list = 0
   @fac_mark_atten = 0
   @fac_spl_atten = 0
   @fac_spl_atten_param = 0
   @fac_time = 0
   @admin = 0 
   @adm_user = 0
   @adm_log = 0
   @adm_cat = 0
   @adm_course = 0
   @adm_subject = 0 
   @adm_club = 0
   @adm_holiday =0
   @adm_year_end =0
   @rep =0
   @rep_att=0
   arrr                     = [] 
   isloggeduserid      = session[:logedUserId]!=nil && session[:logedUserId]!='' ? session[:logedUserId] : 0
   compCodes           = session[:loggedUserCompCode]
   tnsbs               = TrnUserAccess.where("ua_compcode =? AND ua_userid =?",compCodes,isloggeduserid)
   if tnsbs.length >0
        tnsbs.each do |newitem|

          if newitem.ua_formname.to_s == 'student_list' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'STD') && newitem.ua_action !=nil && newitem.ua_action !=''
               
               @student      += 1   
                    @std_list    +=1
                    formcontroller = newitem.ua_formname.to_s.split("/")
                    actioncontroller = ""
                    if formcontroller && formcontroller.length>0
                        actioncontroller= formcontroller[0]
                    else
                        actioncontroller =  newitem.ua_formname
                    end
                  arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'print_student_id_card' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'STD') && newitem.ua_action !=nil && newitem.ua_action !=''
               
               @student      += 1   
               @std_i_card    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'student_transaction_list' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'STD') && newitem.ua_action !=nil && newitem.ua_action !=''
               
               @student      += 1   
               @std_trans_list    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'student_data_import' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'STD') && newitem.ua_action !=nil && newitem.ua_action !=''
               @student      += 1   
               @std_import    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'component_list' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'FEE') && newitem.ua_action !=nil && newitem.ua_action !=''
               
               @fee      += 1   
               @fee_comp_list    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'fee_list' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'FEE') && newitem.ua_action !=nil && newitem.ua_action !=''
               
               @fee      += 1   
               @fees_list    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'time_table' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'TT') && newitem.ua_action !=nil && newitem.ua_action !=''
               @time      += 1   
               @time_create    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'time_table_date_parameter' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'TT') && newitem.ua_action !=nil && newitem.ua_action !=''
               @time      += 1   
               @time_date    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'faculty_list' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'FLT') && newitem.ua_action !=nil && newitem.ua_action !=''
               @fac      += 1   
               @fac_list    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'mark_attendance' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'FLT') && newitem.ua_action !=nil && newitem.ua_action !=''
               @fac      += 1   
               @fac_mark_atten    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'special_attendance' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'FLT') && newitem.ua_action !=nil && newitem.ua_action !=''
               @fac      += 1  
               @fac_spl_atten    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'special_attendance_params' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'FLT') && newitem.ua_action !=nil && newitem.ua_action !=''
               @fac      += 1  
               @fac_spl_atten_param    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'time_table/faculty_view' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'FLT') && newitem.ua_action !=nil && newitem.ua_action !=''
               @fac      += 1
               @fac_time    +=1
               actioncontroller =  newitem.ua_formname
               # formcontroller = newitem.ua_formname.to_s.split("/")
               # actioncontroller = ""
               # if formcontroller && formcontroller.length>0
               #      actioncontroller= formcontroller[0]
               # else
               #      actioncontroller =  newitem.ua_formname
               # end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'create_user' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'ADM') && newitem.ua_action !=nil && newitem.ua_action !=''
               @admin      += 1   
               @adm_user    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'log_audit' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'ADM') && newitem.ua_action !=nil && newitem.ua_action !=''
               @admin      += 1   
               @adm_log    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'category_list' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'ADM') && newitem.ua_action !=nil && newitem.ua_action !=''
               @admin      += 1   
               @adm_cat    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'course_list' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'ADM') && newitem.ua_action !=nil && newitem.ua_action !=''
               @admin      += 1   
               @adm_course    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'subject_list' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'ADM') && newitem.ua_action !=nil && newitem.ua_action !=''
               @admin      += 1   
               @adm_subject    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
	  if newitem.ua_formname.to_s == 'house_list' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'ADM') && newitem.ua_action !=nil && newitem.ua_action !=''
               @admin      += 1   
               @adm_club    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'holiday' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'ADM') && newitem.ua_action !=nil && newitem.ua_action !=''
               @admin      += 1   
               @adm_holiday    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
          if newitem.ua_formname.to_s == 'year_end_process' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'ADM') && newitem.ua_action !=nil && newitem.ua_action !=''
               @admin      += 1   
               @adm_year_end    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end
	  if newitem.ua_formname.to_s == 'attendance_reports' && newitem.ua_subheading.to_s.downcase==''  && ( newitem.ua_heading == 'REP') && newitem.ua_action !=nil && newitem.ua_action !=''
               @rep      += 1   
               @rep_att    +=1
               formcontroller = newitem.ua_formname.to_s.split("/")
               actioncontroller = ""
               if formcontroller && formcontroller.length>0
                    actioncontroller= formcontroller[0]
               else
                    actioncontroller =  newitem.ua_formname
               end
               arrr.push actioncontroller
                    
          end

       end ### end each loop

   end ## end if
  return arrr
end



end
