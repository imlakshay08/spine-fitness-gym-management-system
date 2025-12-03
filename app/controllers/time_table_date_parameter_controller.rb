class TimeTableDateParameterController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:get_all_subjects,:get_timetable,:get_faculty,:get_all_faculty
     helper_method :get_faculty_timetable,:get_course_detail
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @time_table_dt_params         = MstTimeTableDateParam.where("tt_dtp_compcode =? AND id=?", @compcodes, params[:id])
        if params[:id].to_i>0
         # @time_table     = MstTimeTable.where("id=?",params[:id])
         @time_table_dt_param   = MstTimeTableDateParam.where("tt_dtp_compcode=? AND id=?",@compcodes, params[:id]).first
        end
        #@time_table_list=get_time_table()
        @SubjectList    = MstSubjectList.where("sub_compcode =? AND sub_name != ''  ",@compcodes)
        @Faculty        = MstFaculty.where("fclty_compcode =? AND fclty_name != ''  ",@compcodes).order("fclty_name ASC")
        @CourseList     = MstCourseList.where("crse_compcode =? AND crse_code != ''  ",@compcodes)

    end

    def ajax_process
        @compcodes       = session[:loggedUserCompCode]
        if params[:identity] != nil && params[:identity] != '' && params[:identity] == 'TIMETABLEDATEPARAM'
            create();
            return
        elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'BRINGDATE'
            bring_from_upto_date();
            return
        end
    end

    def create
      @compcodes = session[:loggedUserCompCode]
      message = ""
      profileid = ""
      isFlags = true
      mid = params[:mid]
      year = params[:tt_dtp_year]
      course = params[:tt_dtp_course]
      sem = params[:tt_dtp_sem]
    
      # Validation checks
      if year.to_s.blank?
        message = "Year is Required"
        isFlags = false
      elsif course.to_s.blank?
        message = "Course is Required"
        isFlags = false
      elsif sem.to_s.blank?
        message = "Semester is Required"
        isFlags = false
      elsif params[:tt_dtp_fromdate].to_s.blank?
        message = "From Date is Required"
        isFlags = false
      elsif params[:tt_dtp_uptodate].to_s.blank?
        message = "Upto Date is Required"
        isFlags = false
      end
    
      if isFlags
        # Check if record exists to update
        chkgrpobj = MstTimeTableDateParam.where(
          tt_dtp_compcode: @compcodes,
          tt_dtp_year: year,
          tt_dtp_course: course,
          tt_dtp_sem: sem
        ).first
    
        if chkgrpobj
          profileid = chkgrpobj.id
          chkgrpobj.update(time_table_date_params)
          message = "Data updated successfully"
          modulename = "Time Table Date Parameter"
          description = "Time Table Date Parameter Update: #{course}"
          process_request_log_data("UPDATE", modulename, description)
        else
          # Create a new record if not found
          @savegrp = MstTimeTableDateParam.new(time_table_date_params)
          if @savegrp.save
            profileid = @savegrp.id
            message = "Data saved successfully"
            modulename = "Time Table Date Parameter"
            description = "Time Table Date Parameter Save: #{course}"
            process_request_log_data("SAVE", modulename, description)
          else
            isFlags = false
            message = "Error while saving data"
          end
        end
      end
    
      # Set session variables
      session[:isErrorhandled] = isFlags ? nil : 1
      session[:postedpamams] = nil if isFlags
    
      # Respond with JSON
      respond_to do |format|
        format.json { render json: { "message": message, "profileid": profileid, "status": isFlags } }
      end
    end
    

    def time_table_date_params
        @compcodes      = session[:loggedUserCompCode] 
        params[:tt_dtp_compcode] = session[:loggedUserCompCode]
        params.permit(:tt_dtp_compcode,:tt_dtp_year,:tt_dtp_course,:tt_dtp_sem,:tt_dtp_fromdate,:tt_dtp_uptodate)
    end

    private
    def bring_from_upto_date
        @compcodes   = session[:loggedUserCompCode] 
        year         = params[:year]
        course       = params[:course]
        sem          = params[:semester]
        from_date    =""
        upto_date    =""
        message      =""
        timetabledtparam=[]
        isFlags = false

      
      if course.present? && sem.present?
        timetabledtparam = MstTimeTableDateParam.select("tt_dtp_fromdate,tt_dtp_uptodate").where("tt_dtp_compcode=? AND tt_dtp_year=? AND tt_dtp_course=? AND tt_dtp_sem=?",@compcodes,year,course,sem).first
        isFlags = true
        if timetabledtparam
          from_date = formatted_date(timetabledtparam.tt_dtp_fromdate)
          upto_date = formatted_date(timetabledtparam.tt_dtp_uptodate)
          isFlags = true
        end
       end
      
        respond_to do |format|
          format.json { render json: { 'data' => timetabledtparam,'from_date' => from_date, 'upto_date' => upto_date,'message' => '', status: isFlags } }
        end
    end
end
