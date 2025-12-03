class SubjectListController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    helper_method :get_course_detail
    def index
        @compcodes      = session[:loggedUserCompCode] 
        month_number     =  Time.now.month
        month_begin      =  Date.new(Date.today.year, month_number)
        begdate          =  Date.parse(month_begin.to_s)
        @nbegindate      =  begdate.strftime('%d-%b-%Y')
        month_ending     =  month_begin.end_of_month
        endingDate       =  Date.parse(month_ending.to_s)
        @enddate         =  endingDate.strftime('%d-%b-%Y')	
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        @subject_list = get_subject_list()
        @CourseList = MstCourseList.where(["crse_compcode =?",@compcodes]) 
        printPath     =  "subject_list/1_prt_subject_list.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'subject'
              
              @subjectdetail   = print_subject_list()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = SubjectPdf.new(@subjectdetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_subject_list.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def ajax_process
        @compcodes      = session[:loggedUserCompCode] 
        if params[:identity] != nil && params[:identity] != '' && params[:identity] == 'SEMESTER'
            get_semesters();
            return
        elsif params[:identity]!=nil && params[:identity]!= '' && params[:identity] == 'STUDENTDTLS'
            search_student_detail_listed()
            return
        elsif params[:identity] !=nil && params[:identity] !='' && params[:identity]=='STUDENTLIST'
            show_student_list();
            return 
        elsif params[:identity] !=nil && params[:identity] !='' && params[:identity]=='STUDNTATTNDNC'
            save_student_attendnce();
            return 
        elsif params[:identity] !=nil && params[:identity] !='' && params[:identity]=='UPDTPRDS'
            update_student_period();
            return 
        elsif params[:identity] !=nil && params[:identity] !='' && params[:identity]=='BRINGSTUDENTLIST'
            get_student_list_on_change_actvty();
            return 
        elsif params[:identity] !=nil && params[:identity] !='' && params[:identity]=='ACTIVITYSEARCH'
            get_smart_search_activity();
            return 
        elsif params[:identity] !=nil && params[:identity] !='' && params[:identity]=='DELETEFROMATTENDANCE'
            delete_from_attendance();
            return 
        end
            
    end

    def add_subject
        @compcodes      = session[:loggedUserCompCode]
       
        @CourseList = MstCourseList.where(["crse_compcode =?",@compcodes]) 
        @Listsemester = []
        @CourseList.each do |course|
          duration = course.crse_duration
          @Listsemester += get_semester_list(duration)
        end
        
        @Listsemester.uniq!
        @subject = nil
        if params[:id].to_i>0
          
            @subject= MstSubjectList.where("sub_compcode=? AND id=?",@compcodes,params[:id]).first
          
            @selected_semester = @subject.sub_sem if @subject.present?
         end
    end

    def referesh_subject_list
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        isFlags = true
        redirect_to  "#{root_url}subject_list"
    end

    def create
        @compcodes      = session[:loggedUserCompCode] 
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:sub_code].to_s.blank?
           flash[:error] =  "Subject Code is Required"
           isFlags = false
        end
        if params[:sub_name].to_s.blank?
          flash[:error] =  "Subject Name is Required"
          isFlags = false
        end
        if params[:sub_type].to_s.blank?
            flash[:error] =  "Subject Type is Required"
            isFlags = false
          end
          if params[:sub_crse].to_s.blank?
            flash[:error] =  "Subject Course is Required"
            isFlags = false
          end
          if params[:sub_sem].to_s.blank?
            flash[:error] =  "Subject Semester is Required"
            isFlags = false
          end
        currentgrp =  params[:cur_sub_code].to_s.strip
        newgroup   =  params[:sub_code].to_s.strip
        active     =  params[:sub_activ].to_s.strip
        type       =  params[:sub_type].to_s.strip
        course     =  params[:sub_crse].to_s.strip
        semester   =  params[:sub_sem].to_s.strip
        semesterHours=params[:sub_sem_hrs].to_s.strip
        weekHours=params[:sub_week_hrs].to_s.strip
        isOptional = params[:sub_isoptional].to_s.strip

    
        if params[:mid].to_i>0
            if currentgrp.to_s.downcase != newgroup.to_s.downcase
                chkgrpobj   = MstSubjectList.where("sub_compcode=? AND  LOWER(sub_code)=? ",@compcodes,newgroup.to_s.downcase)
                if chkgrpobj.length>0
                    flash[:error] = "Could not create duplicate Subject."
                    isFlags        = false
                end
            end
    
          if isFlags
                chkgrpobj   = MstSubjectList.where("sub_compcode=? AND id=?",@compcodes,mid).first
                if chkgrpobj
                    chkgrpobj.update(subject_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                    modulename = "Subject List"
                    description = "Subject List Save: #{params[:sub_code]}"
                    process_request_log_data("SAVE", modulename, description)
               
                end
          end
        else
            chkgrpobj   = MstSubjectList.where("sub_compcode=? AND LOWER(sub_code)=?",@compcodes,newgroup.to_s.downcase)
            if chkgrpobj.length>0
              flash[:error] = "Could not be create duplicate."
             isFlags        = false
            end
              if isFlags
                  savegrp = MstSubjectList.new(subject_params)
                  if savegrp.save
                      flash[:error] = "Data saved successfully"
                      isFlags       = true
                      modulename = "Subject List"
                      description = "Subject List Update: #{params[:sub_code]}"
                      process_request_log_data("UPDATE", modulename, description)
                  end
              end
    
        end
        if !isFlags
            session[:isErrorhandled] = 1
            session[:postedpamams]   = params
        else
            session[:isErrorhandled] = nil
            session[:postedpamams]   = nil
            isFlags = true
        end
        rescue Exception => exc
            flash[:error] =  "ERROR: #{exc.message}"
            session[:isErrorhandled] = 1
            isFlags = false
        end
        if isFlags
            redirect_to  "#{root_url}subject_list"
        else
            if params[:mid].to_i>0 
                redirect_to  "#{root_url}subject_list/add_subject/"+params[:mid].to_s
            else
                redirect_to  "#{root_url}subject_list/add_subject"
            end
              
        end
    
    end

    def destroy
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i >0
            @ListSate =  MstSubjectList.where("sub_compcode=? AND id=?", @compcodes,params[:id].to_i).first
               if @ListSate
                     @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
       end
       redirect_to "#{root_url}subject_list"
    end

    
    def get_semesters
        @compcodes = session[:loggedUserCompCode]
        course_code = params[:course_code]
        semesters = []
        isflags = false
        course = MstCourseList.select("crse_duration").where("crse_compcode = ? AND id = ?", @compcodes, course_code).first
      
        if course
          duration = course.crse_duration
          case duration
          when '6 Months'
            # No semesters for 6-month courses
            semesters = [1]
            isflags = true
          when '1 Year'
            semesters = [1, 2]
            isflags = true
          when '2 Year'
            semesters = [1, 2, 3, 4]
            isflags = true
          when '3 Year'
            semesters = [1, 2, 3, 4, 5, 6]
            isflags = true
          else
            # Handle any unexpected cases
            semesters = []
            isflags = false
          end
        end
      
        respond_to do |format|
          format.json { render json: { 'data' => semesters, 'message' => '', status: isflags } }
        end
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

    private
    def get_subject_list
        @compcodes      = session[:loggedUserCompCode] 
        if params[:page].to_i >0
            pages = params[:page]
            else
            pages = 1
            end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
             session[:req_subject_list] = nil
             session[:req_course_search] = nil
          # end
          filter_search = params[:subject_list] !=nil && params[:subject_list] != '' ? params[:subject_list].to_s.strip : session[:req_subject_list].to_s.strip       
          course_search = params[:course_search] !=nil && params[:course_search] != '' ? params[:course_search].to_s.strip : session[:req_course_search].to_s.strip

          iswhere       = "sub_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( sub_code LIKE '%#{filter_search}%' OR sub_name LIKE '%#{filter_search}%')"
            @subject_list_search       = filter_search
            session[:req_subject_list] = filter_search
          end    
          
          if course_search !=nil && course_search !=''
            iswhere +=" AND ( sub_crse LIKE '%#{course_search}%' )"
            @course_search       = course_search
            session[:req_course_search] = course_search
          end    
        
          stdob =  MstSubjectList.where(iswhere).order("sub_code ASC")
          return stdob

    end

    def print_subject_list
      @compcodes      = session[:loggedUserCompCode] 
      iswhere         = "sub_compcode ='#{@compcodes}'"
      filter_search   = session[:req_subject_list]   
      if filter_search !=nil && filter_search !=''
          iswhere +=" AND ( sub_code LIKE '%#{filter_search}%' OR sub_name LIKE '%#{filter_search}%')"
        end    
      isselect = "mst_subject_lists.*,'' as coursename,'' as coursecode"
      stdob =  MstSubjectList.select(isselect).where(iswhere).order("sub_code ASC")
      if stdob.length >0
        stdob.each do |newitesm|
        courseobj = get_course_detail(newitesm.sub_crse)
      if courseobj
        newitesm.coursename = courseobj.crse_descp
        newitesm.coursecode = courseobj.crse_code
      end
    end
      return stdob
    end

    end

    private
    def subject_params
        params[:sub_compcode]	    = @compcodes
        params.permit(:sub_compcode,:sub_code,:sub_name,:sub_type,:sub_activ,:sub_crse,:sub_sem,:sub_sem_hrs,:sub_week_hrs,:sub_isoptional)
    end

 private
 def search_student_detail_listed
  compcodes = session[:loggedUserCompCode]
  requesttype = params[:requesttype]
  sp_att_std_rollno = params[:sp_att_std_rollno].to_s.strip.upcase
  sp_att_std_name = params[:sp_att_std_name].to_s.strip
  sp_att_crse = params[:sp_att_crse].to_s
  sp_att_sem  = params[:sp_att_sem].to_s

  isFlags = false
  sewdobj = nil

 isselect = "CONCAT(mst_students.stdnt_fname, ' ', mst_students.stdnt_lname) AS employeename,
            mst_students.stdnt_reg_no AS employeecode"

  query = MstStudent
            .select(isselect)
            .joins("INNER JOIN mst_student_dtls ON mst_student_dtls.stdnt_dtl_code = mst_students.stdnt_reg_no
                    AND mst_student_dtls.stdnt_dtl_compcode = mst_students.stdnt_compcode")
            .joins("INNER JOIN mst_stdnt_gen_dtls ON mst_stdnt_gen_dtls.stdnt_gn_code = mst_students.stdnt_reg_no
                    AND mst_stdnt_gen_dtls.stdnt_gn_compcode = mst_students.stdnt_compcode")
            .where("mst_students.stdnt_compcode = ?", compcodes)
            .where("mst_student_dtls.stdnt_dtl_crse = ?", sp_att_crse)
            .where("mst_stdnt_gen_dtls.stdnt_gn_cur_sem = ?", sp_att_sem)

  if requesttype == 'CODE'
    sewdobj = query.where("UPPER(mst_students.stdnt_reg_no) = ?", sp_att_std_rollno).first
    isFlags = sewdobj.present?
  else
    sewdobj = query.where("mst_students.stdnt_fname LIKE ? OR mst_students.stdnt_lname LIKE ?",
                          "%#{sp_att_std_name}%", "%#{sp_att_std_name}%").order("mst_students.stdnt_fname ASC")
    isFlags = sewdobj.any?
  end

  respond_to do |format|
    format.json { render json: { 'data'=> sewdobj, status: isFlags } }
  end
 end

  private
  def show_student_list
      compcode = session[:loggedUserCompCode]
      student_rollno = params[:student_rollno]
      isFlags = true
      message = ""
      vhtml = ""
    
      if compcode.nil?
        isFlags = false
        message = "Company code not found in session."
      elsif student_rollno.blank?
        isFlags = false
        message = "Student Roll No. is missing."
      else
        @specialattndnce = TrnSpecialAttendance.where("sp_att_compcode = ? AND sp_att_std_rollno = ?", compcode, student_rollno)
        
        if @specialattndnce.any?
          vhtml = render_to_string(template: 'special_attendance/view_special_attendance', layout: false, locals: { specialattndnce: @specialattndnce })
        else
          isFlags = false
          message = "No records found."
        end
      end
    
      render json: { 'data' => vhtml, 'status' => isFlags, 'message' => message }
  end

  private
  def save_student_attendnce
    compcodes = session[:loggedUserCompCode]
    course = params[:sp_att_crse]
    faculty   = params[:sp_att_fclty]
    house = params[:sp_att_house]
    semester = params[:sp_att_sem]
    raw_date = params[:sp_att_date]
    date = Date.strptime(raw_date, '%d-%b-%Y').strftime('%Y-%m-%d')
    activity   = params[:sp_att_actvty].to_s.strip.downcase
    group = params[:sp_att_grp]
    studentd_name = params[:sp_att_std_name]
    rollno = params[:sp_att_std_rollno].to_s
    footerid  = params[:specialAttendId] !=nil && params[:specialAttendId] !='' ? params[:specialAttendId] : 0
    isFlags   = true
    message   = ""

    time_table_params = MstTimeTableDateParam.where(
        tt_dtp_course: params[:sp_att_crse].to_i,
        tt_dtp_sem: params[:sp_att_sem].to_i
      ).first
      date = Date.strptime(params[:sp_att_date], '%d-%b-%Y') # Parse the date

      # Check if the time table parameters exist
      if time_table_params
        from_date = time_table_params.tt_dtp_fromdate
        up_to_date = time_table_params.tt_dtp_uptodate
        date = Date.strptime(params[:sp_att_date], '%d-%b-%Y') # Parse the date
    
        # Validate if the date is within the range
        if date >= from_date && date <= up_to_date
          isFlags = true
        else
          message = "Attendance date must be between #{formatted_date(from_date)} and #{formatted_date(up_to_date)}."
          isFlags = false
        end
      end

          # Check if the attendance date is a holiday
    holiday = MstHoliday.where(holiday_compcode: compcodes, holiday_date: date).first
    if holiday
      message = "Attendance cannot be marked on #{date.strftime('%d-%b-%Y')} as it is a holiday (#{holiday.holiday_descp})."
      isFlags = false
    end
      if isFlags

                  procescount =  process_qualification(faculty)
                  if procescount.to_i >0
                    isFlags = true
                    if footerid.to_i >0
                      message = "Data updated sucessfully"
                    else
                      message = "Data saved sucessfully"
                    end
      
                  else
                    message = "Course/Semester doesn't match with Student details!"
		    isFlags = false   
                  end
           
    end     
    @adspecialattend = get_special_attendnc_information(compcodes, date, faculty, course, house, semester)
  vhtml   = render_to_string :template  => 'special_attendance/_view_special_attndnc',:layout => false, :locals => { :adspecialattend => @adspecialattend}
  respond_to do |format|
    format.json { render :json => { 'data'=>vhtml,"message"=>message,:status=>isFlags} }
  end
  end

  private
  def process_qualification(sp_att_fclty)
     compcodes          = session[:loggedUserCompCode]
     sp_att_compcode    = compcodes          
     sp_att_fclty       = params[:sp_att_fclty] !=nil && params[:sp_att_fclty]!='' ? params[:sp_att_fclty] : ''
     raw_date        = params[:sp_att_date] !=nil && params[:sp_att_date] !='' ? params[:sp_att_date] : ''
     sp_att_date = Date.strptime(raw_date, '%d-%b-%Y').strftime('%Y-%m-%d')
     sp_att_crse        = params[:sp_att_crse] !=nil && params[:sp_att_crse] !='' ? params[:sp_att_crse] : ''
     sp_att_house       = params[:sp_att_house] !=nil && params[:sp_att_house] !='' ? params[:sp_att_house] : ''
     sp_att_sem         = params[:sp_att_sem] !=nil && params[:sp_att_sem] !='' ? params[:sp_att_sem] : ''
     sp_att_actvty      = params[:sp_att_actvty] !=nil && params[:sp_att_actvty] !='' ? params[:sp_att_actvty] : ''
     sp_att_grp         = params[:sp_att_grp] !=nil && params[:sp_att_grp] !='' ? params[:sp_att_grp] : ''
     sp_att_std_name    = params[:sp_att_std_name] !=nil && params[:sp_att_std_name] !='' ? params[:sp_att_std_name] : ''
     sp_att_std_rollno  = params[:sp_att_std_rollno] !=nil && params[:sp_att_std_rollno] !='' ? params[:sp_att_std_rollno] : ''
     footerid           = params[:specialAttendId] !=nil && params[:specialAttendId] !='' ? params[:specialAttendId] : 0

    student_course = MstStudentDtl.where(stdnt_dtl_compcode: sp_att_compcode, stdnt_dtl_code: sp_att_std_rollno).pluck(:stdnt_dtl_crse).first
    student_sem = MstStdntGenDtl.where(stdnt_gn_compcode: sp_att_compcode, stdnt_gn_code: sp_att_std_rollno).pluck(:stdnt_gn_cur_sem).first

    if student_course.to_i != sp_att_crse.to_i
      return 0 
    end

    if student_sem.to_i != sp_att_sem.to_i
      return 0  
    end

     counts = 0;
       if sp_att_fclty !=nil && sp_att_fclty !=''
           process_save_qualification(compcodes,sp_att_fclty,sp_att_date,sp_att_crse,sp_att_house,sp_att_sem,sp_att_actvty,sp_att_grp,sp_att_std_name,sp_att_std_rollno,footerid)
           counts = 1;
       end
       return counts;

end

  private
  def process_save_qualification(sp_att_compcode,sp_att_fclty,sp_att_date,sp_att_crse,sp_att_house,sp_att_sem,sp_att_actvty,sp_att_grp,sp_att_std_name,sp_att_std_rollno,footerid)
    sp_att_actvty = sp_att_actvty.to_s.strip.downcase if sp_att_actvty.present?
      mstseuobj =   TrnSpecialAttendance.where("sp_att_compcode =? AND sp_att_std_rollno = ? AND sp_att_date =? AND sp_att_fclty = ? AND sp_att_crse = ? AND sp_att_house = ? AND sp_att_sem=? AND sp_att_actvty=?",sp_att_compcode,sp_att_std_rollno,sp_att_date,sp_att_fclty,sp_att_crse,sp_att_house,sp_att_sem,sp_att_actvty).first
      if mstseuobj
        mstseuobj.update(:sp_att_fclty=>sp_att_fclty,:sp_att_date=>sp_att_date,:sp_att_crse=>sp_att_crse,:sp_att_house=>sp_att_house,:sp_att_sem=>sp_att_sem,:sp_att_actvty=>sp_att_actvty,:sp_att_grp=>sp_att_grp,:sp_att_std_name=>sp_att_std_name,:sp_att_std_rollno=>sp_att_std_rollno,:sp_att_prd1=>"N",:sp_att_prd2=>"N",:sp_att_prd3=>"N",:sp_att_prd4=>"N",:sp_att_prd5=>"N",:sp_att_prd6=>"N",:sp_att_prd7=>"N",:sp_att_prd8=>"N")
          ## execute message if required
      else

          mstsvqlobj = TrnSpecialAttendance.new(:sp_att_compcode=>sp_att_compcode,:sp_att_fclty=>sp_att_fclty,:sp_att_date=>sp_att_date,:sp_att_crse=>sp_att_crse,:sp_att_house=>sp_att_house,:sp_att_sem=>sp_att_sem,:sp_att_actvty=>sp_att_actvty,:sp_att_grp=>sp_att_grp,:sp_att_std_name=>sp_att_std_name,:sp_att_std_rollno=>sp_att_std_rollno,:sp_att_prd1=>"N",:sp_att_prd2=>"N",:sp_att_prd3=>"N",:sp_att_prd4=>"N",:sp_att_prd5=>"N",:sp_att_prd6=>"N",:sp_att_prd7=>"N",:sp_att_prd8=>"N")
          if mstsvqlobj.save
              ## execute message if required
          end
      end
  end

  private
  def update_student_period
    compcodes = session[:loggedUserCompCode]
    rollno = params[:student_rollno] || []
    period1 = params[:sp_att_prd1] || []
    period2 = params[:sp_att_prd2] || []
    period3 = params[:sp_att_prd3] || []
    period4 = params[:sp_att_prd4] || []
    period5 = params[:sp_att_prd5] || []
    period6 = params[:sp_att_prd6] || []
    period7 = params[:sp_att_prd7] || []
    period8 = params[:sp_att_prd8] || []
    course = params[:sp_att_crse] 
    faculty   = params[:sp_att_fclty]
    house = params[:sp_att_house]
    semester = params[:sp_att_sem]
    raw_date = params[:sp_att_date]
    date = Date.strptime(raw_date, '%d-%b-%Y').strftime('%Y-%m-%d')
    activity   = params[:sp_att_actvty]
    group = params[:sp_att_grp]
    studentd_name = params[:sp_att_std_name]
    footerid  = params[:specialAttendId] !=nil && params[:specialAttendId] !='' ? params[:specialAttendId] : 0
  message = ""
  isFlags = true
   mycounters = 0
  if rollno.present?
    i = 0
    rollno.each do |roll|
      # Use separate variables for current period values
      current_period1 = period1[i].to_s.present? && period1[i].to_s == 'Y' ? period1[i].to_s : 'N'
      current_period2 = period2[i].to_s.present? && period2[i].to_s == 'Y' ? period2[i].to_s : 'N'
      current_period3 = period3[i].to_s.present? && period3[i].to_s == 'Y' ? period3[i].to_s : 'N'
      current_period4 = period4[i].to_s.present? && period4[i].to_s == 'Y' ? period4[i].to_s : 'N'
      current_period5 = period5[i].to_s.present? && period5[i].to_s == 'Y' ? period5[i].to_s : 'N'
      current_period6 = period6[i].to_s.present? && period6[i].to_s == 'Y' ? period6[i].to_s : 'N'
      current_period7 = period7[i].to_s.present? && period7[i].to_s == 'Y' ? period7[i].to_s : 'N'
      current_period8 = period8[i].to_s.present? && period8[i].to_s == 'Y' ? period8[i].to_s : 'N'
    
      # Fetch the attendance record
      attendance_record = TrnSpecialAttendance.where("sp_att_compcode = ? AND sp_att_std_rollno = ? AND sp_att_date =? AND sp_att_fclty = ? AND sp_att_crse = ? AND sp_att_house = ? AND sp_att_sem=? AND sp_att_actvty=?", compcodes, roll,date,faculty,course,house,semester,activity).first
    
      # Update the attendance record if it exists
      if attendance_record
        attendance_record.update(
          sp_att_prd1: current_period1,
          sp_att_prd2: current_period2,
          sp_att_prd3: current_period3,
          sp_att_prd4: current_period4,
          sp_att_prd5: current_period5,
          sp_att_prd6: current_period6,
          sp_att_prd7: current_period7,
          sp_att_prd8: current_period8
        )
      end
    
      mycounters += 1
      i += 1
    end
   
  end
  if mycounters.to_i >0
      message = "Attendance Marked Successfully."
      isFlags = true
  else
      message = "Invalid input data."
      isFlags = false
  end
  @adspecialattend = get_special_attendnc_information(compcodes, date, faculty, course, house, semester, activity)
  vhtml   = render_to_string :template  => 'special_attendance/_view_special_attndnc',:layout => false, :locals => { :adspecialattend => @adspecialattend}
  respond_to do |format|
    format.json { render :json => { 'data'=>vhtml,"message"=>message,:status=>isFlags} }
  end
  end

  private
  def get_student_list_on_change_actvty
    compcodes = session[:loggedUserCompCode]
    course = params[:sp_att_crse] 
    faculty   = params[:sp_att_fclty]
    house = params[:sp_att_house]
    semester = params[:sp_att_sem]
    raw_date = params[:sp_att_date]
    date = Date.strptime(raw_date, '%d-%b-%Y').strftime('%Y-%m-%d') # Convert '23-Jan-2025' to '2025-01-23'
    activity   = params[:sp_att_actvty].to_s.strip.downcase
    group = params[:sp_att_grp]
    studentd_name = params[:sp_att_std_name]
    footerid  = params[:specialAttendId] !=nil && params[:specialAttendId] !='' ? params[:specialAttendId] : 0
    message = ""
    vhtml=""
    isFlags = true
    @adspecialattend = TrnSpecialAttendance.where("sp_att_compcode = ? AND sp_att_date =? AND sp_att_fclty = ? AND sp_att_crse = ?  AND sp_att_house = ? AND sp_att_sem=?", compcodes, date, faculty, course, house, semester) 
    if @adspecialattend.any?
      vhtml = render_to_string(template: 'special_attendance/_view_special_attndnc', layout: false, locals: { adspecialattend: @adspecialattend })
    else
      isFlags = false
    end
    respond_to do |format|
      format.json { render :json => { 'data'=>vhtml,"message"=>message,:status=>isFlags} }
    end
  
  end

  private
  def get_smart_search_activity
    compcodes = session[:loggedUserCompCode]
    course = params[:sp_att_crse] 
    faculty   = params[:sp_att_fclty]
    house = params[:sp_att_house]
    semester = params[:sp_att_sem]
    raw_date = params[:sp_att_date]
    date = Date.strptime(raw_date, '%d-%b-%Y').strftime('%Y-%m-%d')
    isFlags = false
    activtyobj = nil
    arr = []
    isselect = "sp_att_actvty"
  
    activtyobj = TrnSpecialAttendance.where("sp_att_compcode = ? AND sp_att_date =? AND sp_att_fclty = ? AND sp_att_crse = ?  AND sp_att_house = ? AND sp_att_sem=?", compcodes, date, faculty, course, house, semester).select('DISTINCT sp_att_actvty')
                                    
    if activtyobj.length>0
        arr = activtyobj
        isFlags = true
    else
      isFlags = false
    end
  
    respond_to do |format|
      format.json { render json: { 'data'=> arr, status: isFlags } }
    end
  end

  private
  def delete_from_attendance
    compcodes = session[:loggedUserCompCode]
    rollno    = params[:sp_att_std_rollno]
    date      = params[:sp_att_date]
    faculty   = params[:sp_att_fclty]
    course    = params[:sp_att_crse]
    semester  = params[:sp_att_sem]
    activity  = params[:sp_att_actvty].to_s.strip.downcase
  
    # Find the attendance record
    attendance_record = TrnSpecialAttendance.where(
      sp_att_compcode: compcodes,
      sp_att_std_rollno: rollno,
      sp_att_date: date,
      sp_att_fclty: faculty,
      sp_att_crse: course,
      sp_att_sem: semester,
      sp_att_actvty: activity
    ).first
  
    if attendance_record
      attendance_record.destroy
      message = "Student Removed from Attendance Successfully."
      status  = true
    else
      message = "Attendance record not found."
      status  = false
    end
  
    # Return JSON response
    respond_to do |format|
      format.json { render json: { message: message, status: status } }
    end
  end
  

end
