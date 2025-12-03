class MarkAttendanceController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:get_course_detail,:get_students_lists

    def index
        @compcodes      = session[:loggedUserCompCode] 
        month_number     =  Time.now.month
        month_begin      =  Date.new(Date.today.year, month_number)
        begdate          =  Date.parse(month_begin.to_s)
        @nbegindate      =  begdate.strftime('%d-%b-%Y')
        month_ending     =  month_begin.end_of_month
        endingDate       =  Date.parse(month_ending.to_s)
        @enddate         =  endingDate.strftime('%d-%b-%Y')	
        @faclt_id      = session[:facultyId]
        if session[:loginUserName] == 'adm' || session[:loginUserName]  == 'admin'
        @faculty=MstFaculty.where("fclty_compcode =? AND fclty_name != ''  ",@compcodes).order("fclty_name ASC")
        else
          @faculty=MstFaculty.where("fclty_compcode =? AND fclty_name != '' AND id = ? ",@compcodes,@faclt_id).order("fclty_name ASC")
        end
        @subject=MstSubjectList.where("sub_compcode=? AND sub_name!= '' ",@compcodes)
        if params[:id].to_i>0
            @mark_attend=TrnAttendance.where("att_compcode=? AND id=?",@compcodes,params[:id]).first
        end  
        @mark_attendance=TrnAttendance.where("att_compcode=? AND id=?",@compcodes,params[:id])
    end

    def ajax_process
        @compcodes = session[:loggedUserCompCode]
        if params[:identity] != nil && params[:identity] != '' && params[:identity] == 'ATTENDANCE'
          create();
          return
        elsif params[:identity]!=nil && params[:identity]!= '' && params[:identity] == 'SUBJECT'
            get_subject_details();
            return
        elsif params[:identity]!=nil && params[:identity]!= '' && params[:identity] == 'FETCH_SUBJECTS'
           fetch_subjects_by_faculty();
            return
        elsif params[:identity]!=nil && params[:identity]!= '' && params[:identity] == 'FETCH_GROUPS'
          fetch_groups_by_period();
            return
        elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'FILL_NEXT_CLASS'
            fill_next_class();
            return
        elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'DELETEATTEND'
            process_delete_attendance();
            return
        end
   end

   def get_students_lists
    compcodes = session[:loggedUserCompCode]
    group = params[:group]
    att_sem = params[:att_sem]
    att_subject = params[:att_subject]
    faculty = params[:att_fclty]
    date = params[:att_date]
    period = params[:att_period]
    
    isFlags = false
    students = []
  
    if group.present? && att_subject.present?
      # Fetch the subject to check if it is optional
      subject = MstSubjectList.find_by(id: att_subject, sub_compcode: compcodes)
  
      if subject.present?
        is_optional = subject.sub_isoptional == 'Y'
  
        # Adjust query based on optional status
        if is_optional
          # Fetch students who selected the subject as optional
          iswhere = "stdnt_gn_opt_sub = '#{att_subject}' AND stdnt_gn_thry_grp = '#{group}' AND stdnt_gn_compcode = '#{compcodes}' AND stdnt_gn_cur_sem = '#{att_sem}' AND stdnt_gn_status = 'A'"
        else
          # Fetch students based on group type
          if group.match?(/^\d$/) # Theory group
            iswhere = "stdnt_gn_thry_grp = '#{group}' AND stdnt_gn_compcode = '#{compcodes}' AND stdnt_gn_cur_sem = '#{att_sem}' AND stdnt_gn_status = 'A'"
          elsif group.match?(/^[A-Z]$/) # Practical group
            iswhere = "stdnt_gn_prac = '#{group}' AND stdnt_gn_compcode = '#{compcodes}' AND stdnt_gn_cur_sem = '#{att_sem}' AND stdnt_gn_status = 'A'"
          else
            iswhere = nil
          end
        end
  
        if iswhere
          student_codes = MstStdntGenDtl.where(iswhere).pluck(:stdnt_gn_code)
  
          if student_codes.present?
            students = MstStudentDtl
                        .joins("INNER JOIN mst_stdnt_gen_dtls ON mst_stdnt_gen_dtls.stdnt_gn_code = mst_student_dtls.stdnt_dtl_code")
                        .joins("INNER JOIN mst_students ON mst_students.stdnt_reg_no = mst_stdnt_gen_dtls.stdnt_gn_code AND mst_students.stdnt_compcode = '#{compcodes}'")
                        .where("mst_student_dtls.stdnt_dtl_crse = ?", subject.sub_crse) # course filter
                        .where("mst_student_dtls.stdnt_dtl_code IN (?)", student_codes)
                        .select("mst_students.stdnt_reg_no, CONCAT(mst_students.stdnt_fname, ' ', mst_students.stdnt_lname) AS name")
                        .map do |student|
                            attendance_record = TrnAttendance.find_by(
                              att_stdnt_code: student.stdnt_reg_no,
                              att_compcode: compcodes,
                              att_fclty: faculty,
                              att_date: date,
                              att_subject: att_subject,
                              att_period: period,
                              att_grp: group
                            )
                            {
                              code: student.stdnt_reg_no,
                              name: student.name,
                              attendance_status: attendance_record&.att_attnd || 'Y'
                            }
                        end
            isFlags = students.any?
          end

        end
      end
    end
  
    respond_to do |format|
      format.json { render json: { students: students, status: isFlags } }
    end
  end
  
  def create
    @compcodes = session[:loggedUserCompCode]
    isFlags = true
    attendance_data = params[:attendance] # A hash with student codes as keys
    message = ""
    att_crse = params[:att_crse]
    att_sem = params[:att_sem]
    att_date = params[:att_date]
    att_fclty = params[:att_fclty]
    periods = params[:att_period].split(',') if params[:att_period].present?

    begin
        att_date_parsed = Date.strptime(att_date, '%d-%b-%Y') # Parse the date
        year = att_date_parsed.year

      # Fetch the time table parameters
      time_table_params = MstTimeTableDateParam.where(
        tt_dtp_course: att_crse, 
        tt_dtp_sem: att_sem,
        tt_dtp_year: year
      ).first
  
      # Check if the time table parameters exist
      if time_table_params
        from_date = time_table_params.tt_dtp_fromdate
        up_to_date = time_table_params.tt_dtp_uptodate
  
        # Check if the attendance date is within the range
        unless att_date_parsed.between?(from_date, up_to_date)
          message = "Attendance date must be between #{formatted_date(from_date)} and #{formatted_date(up_to_date)}."
          isFlags = false
        end
      end
  
      # Check if the attendance date is a holiday
      holiday = MstHoliday.where(holiday_compcode: @compcodes, holiday_date: att_date_parsed).first
      if holiday
        message = "Attendance cannot be marked on #{att_date_parsed.strftime('%d-%b-%Y')} as it is a holiday (#{holiday.holiday_descp})."
        isFlags = false
      end

      if session[:autherizedUserType] != 'adm'
          cutoff_date = Date.new(year, 11, 1)
          if att_date_parsed < cutoff_date
            message = "Attendance cannot be marked before 01-Nov-#{year}."
            isFlags = false
          end
       end
        
      # Validate that all selected periods have the same subject and group
      if periods.present? && isFlags
        day_of_week = att_date_parsed.strftime('%A').upcase[0..2]
        day_mapping = { 'MON' => 'MON', 'TUE' => 'TUES', 'WED' => 'WED', 'THU' => 'THURS', 'FRI' => 'FRI' }
        db_day_value = day_mapping[day_of_week]
        parsed_date = Date.strptime(att_date, '%d-%b-%Y')
        year = parsed_date.year
        # Fetch timetable entries for selected periods
        timetable_entries = MstTimeTable.where(
          tt_compcode: @compcodes,
          tt_faculty: att_fclty,
          tt_day: db_day_value,
          tt_period: periods,
          tt_year: year
        )
  
        groups = timetable_entries.select(:tt_group).distinct.pluck(:tt_group)
        subject_ids = timetable_entries.pluck(:tt_subject).uniq
        subjects = MstSubjectList.where(id: subject_ids)
  
        if periods.length > 1
          first_subject = subjects.first
          first_group = groups.first
  
          mismatch_found = timetable_entries.any? do |entry|
            subject = subjects.find { |sub| sub.id == entry.tt_subject.to_i }
            subject&.sub_name != first_subject&.sub_name || entry.tt_group != first_group
          end
  
          if mismatch_found
            message = "All selected periods must have the same subject and group!"
            isFlags = false
          end
        else
          # For single period, ensure there's at least one valid group
          isFlags = groups.any?
        end
      end
  
      # Proceed to save attendance if all validations pass
      if attendance_data.present? && isFlags
        attendance_data.each do |student_code, status|
          periods.each do |period|
            existing_record = TrnAttendance.find_by(
              att_compcode: @compcodes,
              att_stdnt_code: student_code,
              att_fclty: att_fclty,
              att_date: att_date,
              att_subject: params[:att_subject],
              att_period: period.strip,
              att_grp: params[:att_grp]
            )
  
            if existing_record
              existing_record.update(att_attnd: status)
            else
              new_record = TrnAttendance.new(
                att_compcode: @compcodes,
                att_stdnt_code: student_code,
                att_attnd: status,
                att_fclty: att_fclty,
                att_date: att_date,
                att_subject: params[:att_subject],
                att_period: period.strip,
                att_grp: params[:att_grp]
              )
  
              unless new_record.save
                message = "Failed to save attendance for student #{student_code}"
                isFlags = false
                break
              end
            end
          end
          break unless isFlags
        end

        if isFlags

          facultyname = ""
          if att_fclty.present?
        facobj = get_faculty_detail(att_fclty)
        if facobj
            facultyname = facobj.fclty_name
        end
      end
          modulename  = "Mark Attendance"
          description = "Mark Attendance #{facultyname} for period #{periods} , Group #{params[:att_grp]}, Date #{att_date}"
          process_request_log_data("SAVE", modulename, description)
        end
  
        message = "Attendance Marked Successfully" if isFlags
      elsif !isFlags
        # message is already set for validation errors
      else
        message = "No attendance data provided"
        isFlags = false
      end
  
    rescue Exception => exc
      message = "Error: #{exc.message}"
      isFlags = false
    end
  
    respond_to do |format|
      format.json { render json: { message: message, status: isFlags } }
      format.any { render json: { message: message, status: isFlags } }
    end
  end  
  
    private
    def get_subject_details
      compcodes = session[:loggedUserCompCode]
      requesttype = params[:requesttype]
      course = params[:course]
      requestname = params[:requestname]
      isFlags = false
      sewdobj = []
      course_details = {}
    
      # Fetch course details if course ID is provided
      course_detail = get_course_detail(course)
      if course_detail.present?
        course_details = {
          course_id: course_detail.id,
          course_code: course_detail.crse_code,
          course_description: course_detail.crse_descp,
          course_duration: course_detail.crse_duration,
          course_term: course_detail.crse_term,
          course_seats: course_detail.crse_seats
        }
      end
    
      if requesttype.to_s == 'CODE'
        # Fetch records based on specific subject `tt_subject`
        sewdobj = MstTimeTable.select("tt_period AS period, tt_group AS `group`,tt_semester AS att_sem")
                              .where(tt_compcode: compcodes, tt_subject: course) # Assuming `course` represents `tt_subject` ID
                              .limit(1)
        isFlags = sewdobj.present?
      else
        # General search by `tt_subject` with optional course filter
        query = MstTimeTable.select("tt_period AS period, tt_group AS `group`, tt_semester AS att_sem")
                            .where("tt_compcode = ? AND tt_subject LIKE ?", compcodes, "%#{requestname}%")
        query = query.where("UPPER(tt_course) = ?", course_detail[:course_code].upcase) if course_detail.present?
    
        sewdobj = query.order("tt_subject ASC")
        isFlags = sewdobj.any?
      end
    
      respond_to do |format|
        format.json { render json: { data: sewdobj, course_details: course_details, status: isFlags } }
      end
    end
    

    private
    def save_attendance
      compcodes = session[:loggedUserCompCode]
      att_stdnt_code   = params[:att_stdnt_code]
      att_attnd    = params[:att_attnd]
      footerid  = params[:markAttendanceId] !=nil && params[:markAttendanceId] !='' ? params[:markAttendanceId] : 0
      isFlags   = false
      message   = ""
      if  att_attnd != nil && att_attnd !=''
            procescount =  process_attendance(att_stdnt_code)
            if procescount.to_i >0
              isFlags = true
              if footerid.to_i >0
                message = "Data updated sucessfully"
              else
                message = "Data saved sucessfully"
              end

            else
              message = "Data could not be processed due to technical issue."
            end
      end
      markAttendance = get_attendance_info(compcodes,att_stdnt_code)
    vhtml   = render_to_string :template  => 'mark_attendance/view_attendance_list',:layout => false, :locals => { :mydata => markAttendance}
    respond_to do |format|
      format.json { render :json => { 'data'=>vhtml,"message"=>message,:status=>isFlags} }
    end
    end

    
    private
    def process_attendance(att_stdnt_code)
       compcodes             = session[:loggedUserCompCode]
    att_stdnt_code          = params[:att_stdnt_code] !=nil && params[:att_stdnt_code]!='' ? params[:att_stdnt_code] : ''
    att_attnd   = params[:att_attnd] !=nil && params[:att_attnd] !='' ? params[:att_attnd] : ''
    att_fclty         = params[:att_fclty] !=nil && params[:att_fclty] !='' ? params[:att_fclty] : ''
    att_date       = params[:att_date] !=nil && params[:att_date] !='' ? params[:att_date] : ''
    att_subject          = params[:att_subject] !=nil && params[:att_subject] !='' ? params[:att_subject] : ''
    att_period        = params[:att_period] !=nil && params[:att_period] !='' ? params[:att_period] : ''
    att_grp        = params[:att_grp] !=nil && params[:att_grp] !='' ? params[:att_grp] : ''
    att_sem        = params[:att_sem] !=nil && params[:att_sem] !='' ? params[:att_sem] : ''

         if att_stdnt_code !=nil && att_stdnt_code !=''
          process_save_attendance(compcodes,att_stdnt_code,att_attnd,att_fclty,att_date,att_subject,att_period,att_grp,att_sem,footerid)
             counts = 1;
         end
         return counts;

  end

    private
    def process_save_attendance(att_compcode,att_stdnt_code,att_attnd,att_fclty,att_date,att_subject,att_period,att_grp,att_sem,footerid)
        mstseuobj =   TrnAttendance.where("att_compcode =? AND id = ?",att_compcode,footerid).first
        if mstseuobj
          mstseuobj.update(:att_stdnt_code=>att_stdnt_code,:att_attnd=>att_attnd,:att_fclty=>att_fclty,:att_date=>att_date,:att_subject=>att_subject,:att_period=>att_period,:att_sem=>att_sem)
            ## execute message if required
        else

            mstsvqlobj = TrnAttendance.new(:att_compcode=>att_compcode,:att_stdnt_code=>att_stdnt_code,:att_attnd=>att_attnd,:att_fclty=>att_fclty,:att_date=>att_date,:att_subject=>att_subject,:att_period=>att_period,:att_sem=>att_sem)
            if mstsvqlobj.save
                ## execute message if required
            end
        end
    end

    private
    def fetch_subjects_by_faculty
      @compcodes = session[:loggedUserCompCode]
      faculty_id = params[:faculty_id]
      selected_date = params[:att_date]
      isFlags = false
      subjects = []
      periods = []
    
      if faculty_id.present? && selected_date.present?

        parsed_date = Date.strptime(selected_date, '%d-%b-%Y')
        year = parsed_date.year
        # Convert selected date to day of the week
        day_of_week = Date.strptime(selected_date, '%d-%b-%Y').strftime('%A').upcase[0..2] # Get first three characters of day in uppercase
    
        # Map full day names to database values
        day_mapping = {
          'MON' => 'MON',
          'TUE' => 'TUES',
          'WED' => 'WED',
          'THU' => 'THURS',
          'FRI' => 'FRI'
        }
    
        # Get the mapped day value
        db_day_value = day_mapping[day_of_week]
    
        # Log the query parameters for debugging
        Rails.logger.debug "Compcode: #{@compcodes}, Faculty ID: #{faculty_id}, Day of Week: #{db_day_value}"
    
        # Fetch subjects, periods, and groups based on faculty and day of week
        subjects = MstTimeTable.where(tt_compcode: @compcodes, tt_faculty: faculty_id, tt_day: db_day_value, tt_year: year)
                                .joins("INNER JOIN mst_subject_lists ON mst_subject_lists.id = mst_time_tables.tt_subject")
                                .select("mst_subject_lists.id, mst_subject_lists.sub_code, mst_subject_lists.sub_crse, mst_subject_lists.sub_sem")
                                .distinct
    
        periods = MstTimeTable.where(tt_compcode: @compcodes, tt_faculty: faculty_id, tt_day: db_day_value, tt_year: year )
                              .select("DISTINCT tt_period")
                              .pluck(:tt_period)
                              .map(&:to_i) # Convert periods to integers for sorting
                              .sort
                              
        isFlags = subjects.any?
      end
    
      respond_to do |format|
        format.json { render json: { 'data' => subjects, 'periods' => periods,status: isFlags } }
      end
    end

    private
    def fetch_groups_by_period
      @compcodes = session[:loggedUserCompCode]
      faculty_id = params[:faculty_id]
      selected_date = params[:att_date]
      selected_periods = params[:att_period]
      isFlags = false
      subjects = []
      groups = []
      message = ""
    
      if faculty_id.present? && selected_date.present?
        day_of_week = Date.strptime(selected_date, '%d-%b-%Y').strftime('%A').upcase[0..2]
        parsed_date = Date.strptime(selected_date, '%d-%b-%Y')
        year = parsed_date.year

        day_mapping = {
          'MON' => 'MON',
          'TUE' => 'TUES',
          'WED' => 'WED',
          'THU' => 'THURS',
          'FRI' => 'FRI'
        }
    
        db_day_value = day_mapping[day_of_week]
    
        # Fetching timetable entries based on faculty, day, and selected periods
        timetable_entries = MstTimeTable.where(
          tt_compcode: @compcodes,
          tt_faculty: faculty_id,
          tt_day: db_day_value,
          tt_period: selected_periods,
          tt_year: year
        )
    
        groups = timetable_entries.select(:tt_group).distinct.pluck(:tt_group)
    
        # Fetch subjects based on timetable entries
        subject_ids = timetable_entries.pluck(:tt_subject).uniq
        subjects = MstSubjectList.where(id: subject_ids)
    
        if selected_periods.length > 1
          first_subject = subjects.first
          first_group = groups.first
    
          mismatch_found = false  # Flag to detect mismatches
    
          timetable_entries.each do |entry|
            subject = subjects.find { |sub| sub.id == entry.tt_subject.to_i }
            if subject&.sub_name != first_subject&.sub_name || entry.tt_group != first_group
              message = "All selected periods must have the same subject and group!"
              mismatch_found = true
              break  # Exit loop early if mismatch is found
            end
          end
    
          isFlags = !mismatch_found
        else
          isFlags = groups.any?
        end
      end
    
      respond_to do |format|
        format.json { render json: { groups: groups, subjects: subjects, subject_id: subjects.first&.id, att_sem: subjects.first&.sub_sem, status: isFlags, message: message } }
      end
    end
    
 private
def process_delete_attendance
  @compcodes = session[:loggedUserCompCode]
  faculty    = params[:faculty]
  date       = params[:date]
  gruop      = params[:gruop]
  periods    = params[:period].to_s.split(',').map(&:strip)

  message = ""
  isFlags = true

  att_date_parsed = Date.strptime(date, '%d-%b-%Y')
  year = att_date_parsed.year

  # Block delete before 1-Nov of same year
  cutoff_date = Date.new(year, 11, 1)
  if att_date_parsed < cutoff_date
    render json: { status: false, message: "Attendance cannot be deleted before 01-Nov-#{year}." }
    return
  end

  # Proceed to delete
  deleted_count = TrnAttendance.where(
    att_compcode: @compcodes,
    att_fclty: faculty,
    att_date: date,
    att_grp: gruop,
    att_period: periods
  ).delete_all

  if deleted_count > 0

    facultyname = ""
    if faculty.present?
      facobj = get_faculty_detail(faculty)
      facultyname = facobj.fclty_name if facobj
    end

    modulename  = "Mark Attendance"
    description = "Delete Attendance #{facultyname} for period #{periods}, Group #{gruop}"
    process_request_log_data("DELETE", modulename, description)

    render json: { status: true, message: "Attendance Record(s) Deleted." }
  else
    render json: { status: false, message: "No record(s) found for given parameters." }
  end
end

    
end
