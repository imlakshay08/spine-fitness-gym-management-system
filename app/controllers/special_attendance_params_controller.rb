class SpecialAttendanceParamsController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:get_all_subjects,:get_timetable,:get_faculty,:get_all_faculty
    helper_method :get_faculty_timetable,:get_course_detail
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @special_attendance_params   = MstSpecialAttendanceParam.where("sp_attp_compcode =? AND id=?", @compcodes, params[:id])
        if params[:id].to_i>0
         # @time_table     = MstTimeTable.where("id=?",params[:id])
        end
        #@time_table_list=get_time_table()
        @SubjectList = MstSubjectList.where("sub_compcode =? AND sub_name != ''  ",@compcodes)
        @faclt_id      = session[:facultyId]
        if session[:loginUserName] == 'adm' || session[:loginUserName]  == 'admin'
        @faculty=MstFaculty.where("fclty_compcode =? AND fclty_name != ''  ",@compcodes).order("fclty_name ASC")
        else
        @faculty=MstFaculty.where("fclty_compcode =? AND fclty_name != '' AND id = ? ",@compcodes,@faclt_id).order("fclty_name ASC")
        end
        @CourseList  = MstCourseList.where("crse_compcode =? AND crse_code != ''  ",@compcodes)
        @Listsemester = []
        @CourseList.each do |course|
          duration = course.crse_duration
          @Listsemester += get_semester_list(duration)
        end
        
        @Listsemester.uniq!
        @special_attendance_param = nil
        if params[:id].to_i>0
          
          @special_attendance_param   = MstSpecialAttendanceParam.where("sp_attp_compcode=? AND id=?",@compcodes, params[:id]).first
          
          @selected_semester = @special_attendance_param.sp_attp_sem if @special_attendance_param.present?
         end
        @HouseList   = MstHouseList.where("hs_compcode =? AND hs_house_name != ''  ",@compcodes)

    end

        
    def get_semester_list(duration)
      case duration
      when '6 Months'
        [1]
      when '1 Year'
        [1, 2]
      when '2 Year'
        [1, 2, 3, 4]
      when '3 Year'
        [1, 2, 3, 4, 5, 6]
      else
        []
      end
    end

    def special_attendance_params_list
      @compcodes      = session[:loggedUserCompCode]
      @cdate          = Time.now.to_date
      @cdate          = Time.now.to_date
          month_number =  Time.now.month
          month_begin  =  Date.new(Date.today.year, month_number)
          begdate      =  Date.parse(month_begin.to_s)
          @nbegindate  =  begdate.strftime('%d-%b-%Y')
          month_ending =  month_begin.end_of_month
          endingdate   =  Date.parse(month_ending.to_s)
          @enddate     =  endingdate.strftime('%d-%b-%Y')
      @special_attendance_params_list =  search_special_attendance_params_list
    end

    def ajax_process
        @compcodes       = session[:loggedUserCompCode]
        if params[:identity] != nil && params[:identity] != '' && params[:identity] == 'SPECIALATTENDPARAM'
            create();
            return
          elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'BRINGCLUB'
            bring_assigned_club();
            return
        end
    end

    def create
      @compcodes      = session[:loggedUserCompCode] 
      isFlags      = true
      mid          = params[:mid]
      message      = ""
      year = params[:sp_attp_year]
      course = params[:sp_attp_course]
      sem = params[:sp_attp_sem]
      profileid    = ""
      mdid         = ""
      mdfiles      = ""
      # begin
          if year.to_s.blank?
               message =  "Year is Required"
              isFlags = false
          elsif course.to_s.blank?
            message =  "Course is Required"
              isFlags = false  
          elsif sem.to_s.blank?
            message =  "Semester is Required"
              isFlags = false
          elsif params[:sp_attp_faculty].to_s.blank?
            message = "Faculty is Required"
              isFlags = false
          elsif params[:sp_attp_club].to_s.blank?
                message = "Club is Required"
                isFlags = false
          end
       if isFlags   

          if params[:mid].to_i>0
            
            if isFlags
                  chkgrpobj   = MstSpecialAttendanceParam.where("sp_attp_compcode=? AND id=?",@compcodes,mid).first
                  if chkgrpobj
                    profileid    = chkgrpobj.id
                      chkgrpobj.update(special_attendance_params)
                      message       = "Data Updated Successfully!"
                      isFlags       = true
                      modulename    = "Special Attendance Parameter"
                      description   = "Special Attendance Parameter Update: #{course}"
                      process_request_log_data("UPDATE", modulename, description)
                  end
            end
          else
                if isFlags
                    @savegrp = MstSpecialAttendanceParam.new(special_attendance_params)
                    if @savegrp.save
                        profileid    = @savegrp.id.to_i
                        message     = "Data Saved Successfully!"
                        isFlags     = true
                        modulename  = "Special Attendance Parameter"
                        description = "Special Attendance Parameter Save: #{course}"
                        process_request_log_data("SAVE", modulename, description)
                  
                    end
                end
      
          end
              
        end
        if !isFlags
          session[:isErrorhandled] = 1
          #session[:postedpamams]   = params
      else
          session[:isErrorhandled] = nil
          session[:postedpamams]   = nil
          isFlags = true
      end
      # rescue Exception => exc
      #     message = "ERROR: #{exc.message}"
      #     session[:isErrorhandled] = 1
      #     isFlags = false
      # end
        respond_to do |format|
          format.json { render :json => {  "message"=>message,:mdid=>mdid,:mdfiles=>mdfiles,:profileid=>profileid,:status=>isFlags} }
        end

  end

  def destroy
    @compcodes      = session[:loggedUserCompCode] 
    if params[:id].to_i >0
      @ListSate =  MstSpecialAttendanceParam.where("sp_attp_compcode=? AND id=?", @compcodes,params[:id].to_i).first
         if @ListSate
               @ListSate.destroy
                   flash[:error] =  "Data deleted successfully."
                   isFlags       =  true
                   session[:isErrorhandled] = nil
           
         end
      end
      redirect_to "#{root_url}special_attendance_params/special_attendance_params_list"
  end

    def special_attendance_params
        @compcodes      = session[:loggedUserCompCode] 
        params[:sp_attp_compcode] = session[:loggedUserCompCode]
        params.permit(:sp_attp_compcode,:sp_attp_year,:sp_attp_course,:sp_attp_sem,:sp_attp_faculty,:sp_attp_club)
    end

    private
    def bring_assigned_club
        @compcodes   = session[:loggedUserCompCode] 
        year         = params[:year]
        course       = params[:course]
        sem          = params[:semester]
        faculty      = params[:faculty]
        club         = ""
        message      = ""
        specialattendparam=[]
        isFlags = false

      
      if faculty.present? && sem.present?
        specialattendparam = MstSpecialAttendanceParam.select("sp_attp_club").where("sp_attp_compcode=? AND sp_attp_year=? AND sp_attp_course=? AND sp_attp_sem=? AND sp_attp_faculty=?",@compcodes,year,course,sem,faculty).first
        isFlags = true
        if specialattendparam
          club = specialattendparam.sp_attp_club
          club_id =  MstHouseList.where("hs_compcode=? AND id=?", @compcodes, club).first
          if club_id
            club_name=club_id.hs_house_name
            isFlags = true
          end
        end
       end
      
        respond_to do |format|
          format.json { render json: { 'data' => specialattendparam,'club'=>club,'club_name'=>club_name,'message' => '', status: isFlags } }
        end
    end

    def search_special_attendance_params_list
      @compcodes    = session[:loggedUserCompCode]
      @pages = params[:page].to_i > 0 ? params[:page].to_i : 1
      
    
      if params[:server_request]!=nil && params[:server_request]!= '' 

     end
      iswhere        = " sp_attp_compcode ='#{@compcodes}'"

    empdata = MstSpecialAttendanceParam.where(iswhere).order('sp_attp_faculty DESC')
    return empdata
    end
end
