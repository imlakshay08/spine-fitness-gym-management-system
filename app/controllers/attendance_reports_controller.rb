require 'csv'

class AttendanceReportsController < ApplicationController
    before_action      :require_login
    before_action      :get_user_access_permissions
    skip_before_action :verify_authenticity_token, :only=> [:index,:ajax_process]
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct  
    def index
      @compcodes   = session[:loggedUserCompCode] 
      @cdate       = Time.now.to_date
      month_number =  Time.now.month
      month_begin  =  Date.new(Date.today.year, month_number)
      begdate      =  Date.parse(month_begin.to_s)
      @nbegindate  =  begdate.strftime('%d-%b-%Y')
      month_ending =  month_begin.end_of_month
      endingdate   =  Date.parse(month_ending.to_s)
      @enddate     =  endingdate.strftime('%d-%b-%Y')
      printcontroll   = "1_prt_attendance_report"
      @printpath      = attendance_reports_path(printcontroll, format: "csv")
      @CourseList     = MstCourseList.where("crse_compcode =? AND crse_code != ''  ", @compcodes)
      @SubjectList    = MstSubjectList.where("sub_compcode =? AND sub_name != ''  ", @compcodes)
      @HouseList = MstHouseList.where("hs_compcode =? AND hs_house_name != ''  ",@compcodes)

      respond_to do |format|
        format.html
        format.csv do
          types = session[:req_report_type]
          if types == 'C'
            filename = "consolidated_report"
            send_data generate_attendance_reports_consolidated, filename: "#{filename}-#{Date.today}.csv"
          elsif types == 'I'
            filename = "individual_subject_wise_report"
            send_data generate_attendance_reports_individual, filename: "#{filename}-#{Date.today}.csv"
          elsif types == 'S'
            filename = "special_attendance_club_wise_report"
            send_data generate_special_attendance_reports, filename: "#{filename}-#{Date.today}.csv"            
          end
        end
      end
    end

    def ajax_process
      @compcodes  = session[:loggedUserCompCode]
      if params[:identity]!=nil && params[:identity]!='' && params[:identity] == 'Y'
        check_attendance() 
         return
      end
   
    end

    def check_attendance
      report_course   = params[:report_course]
      report_semester = params[:report_semester]
      report_type     = params[:report_type]
      asondated       = params[:asondated]
      uptodated       = params[:uptodated]
      report_club     = params[:report_club]

      session[:req_report_course] = report_course
      session[:req_report_semester] = report_semester
      session[:req_report_type] = report_type
      session[:req_asondated] = asondated
      session[:req_uptodated] = uptodated
      session[:req_report_club] = report_club
    
  if report_type == 'C'
    iswhere = "trn_attendances.id>0" 

      if asondated.present?    
        newdated = year_month_days_formatted(asondated)
        iswhere += " AND DATE(att_date) >= '#{newdated}'"
        session[:req_asondated] = asondated
      end
    
      if uptodated.present?
        udated = year_month_days_formatted(uptodated)
        iswhere += " AND DATE(att_date) <= '#{udated}'"
        session[:req_uptodated] = uptodated
      end
    
      if report_course.present?
        iswhere += " AND mst_subject_lists.sub_crse = '#{report_course}'"
        session[:req_report_course] = report_course
      end 
    
      if report_semester.present?
        iswhere += " AND mst_subject_lists.sub_sem = '#{report_semester}'"
        session[:req_report_semester] = report_semester
      end 

    data = TrnAttendance
      .joins("INNER JOIN mst_subject_lists ON trn_attendances.att_subject = mst_subject_lists.id")
      .joins("LEFT JOIN trn_special_attendances ON 
                trn_special_attendances.sp_att_compcode = trn_attendances.att_compcode
                AND trn_special_attendances.sp_att_fclty = trn_attendances.att_fclty
                AND trn_special_attendances.sp_att_date = trn_attendances.att_date
                AND trn_special_attendances.sp_att_std_rollno = trn_attendances.att_stdnt_code")
      .select(
        "trn_attendances.att_stdnt_code AS roll_no,
         SUM(
           CASE 
             WHEN trn_attendances.att_attnd = 'Y' THEN 1
             WHEN trn_attendances.att_attnd = 'N' 
                  AND (
                      (trn_attendances.att_period = '1' AND trn_special_attendances.sp_att_prd1 = 'Y') OR
                      (trn_attendances.att_period = '2' AND trn_special_attendances.sp_att_prd2 = 'Y') OR
                      (trn_attendances.att_period = '3' AND trn_special_attendances.sp_att_prd3 = 'Y') OR
                      (trn_attendances.att_period = '4' AND trn_special_attendances.sp_att_prd4 = 'Y') OR
                      (trn_attendances.att_period = '5' AND trn_special_attendances.sp_att_prd5 = 'Y') OR
                      (trn_attendances.att_period = '6' AND trn_special_attendances.sp_att_prd6 = 'Y') OR
                      (trn_attendances.att_period = '7' AND trn_special_attendances.sp_att_prd7 = 'Y') OR
                      (trn_attendances.att_period = '8' AND trn_special_attendances.sp_att_prd8 = 'Y')
                  )
             THEN 1
             ELSE 0
           END
         ) AS attended,
         COUNT(trn_attendances.att_attnd) AS total"
      )
      .where(iswhere)
      .group("trn_attendances.att_stdnt_code")
    
        respond_to do |format|
          format.json { render json: { 'data' => data, status: data.present? } }
        end
    elsif report_type == 'I'
  iswhere = "trn_attendances.id > 0"
    if asondated.present?
      newdated = year_month_days_formatted(asondated)
      iswhere += " AND DATE(att_date) >= '#{newdated}'"
    end
    if uptodated.present?
      udated = year_month_days_formatted(uptodated)
      iswhere += " AND DATE(att_date) <= '#{udated}'"
    end
    iswhere += " AND mst_subject_lists.sub_crse = '#{report_course}'" if report_course.present?
    iswhere += " AND mst_subject_lists.sub_sem = '#{report_semester}'" if report_semester.present?

    # Get months
    months = TrnAttendance
      .joins("INNER JOIN mst_subject_lists ON trn_attendances.att_subject = mst_subject_lists.id")
      .where(iswhere)
      .pluck(Arel.sql("DISTINCT DATE_FORMAT(att_date, '%b-%Y')"))
      .sort_by { |m| Date.strptime(m, '%b-%Y') }

    # Main attendance query (without special attendance)
    data = TrnAttendance
      .joins("INNER JOIN mst_subject_lists ON trn_attendances.att_subject = mst_subject_lists.id")
      .joins("INNER JOIN mst_students ON trn_attendances.att_stdnt_code = mst_students.stdnt_reg_no")
      .select("
        att_stdnt_code AS roll_no,
        CONCAT(mst_students.stdnt_fname, ' ', mst_students.stdnt_lname) AS name,
        mst_subject_lists.sub_code AS subject_code,
        mst_subject_lists.sub_name AS subject_name,
        DATE_FORMAT(att_date, '%b-%Y') AS month,
        SUM(CASE WHEN att_attnd = 'Y' THEN 1 ELSE 0 END) AS attended,
        SUM(CASE WHEN att_attnd = 'Y' AND att_sp = 'SP' THEN 1 ELSE 0 END) AS special_attended,
        COUNT(att_attnd) AS total_classes
      ")
      .where(iswhere)
      .group("att_stdnt_code, subject_code, month")
      .order("roll_no, subject_code, month")

    formatted_data = format_attendance_data(data, months)

    respond_to do |format|
      format.json { render json: { 'data' => formatted_data, 'months' => months, status: formatted_data.present? } }
    end

      elsif report_type == 'S'
        iswhere = "trn_special_attendances.id>0" 

        if asondated.present?    
          newdated = year_month_days_formatted(asondated)
          iswhere += " AND DATE(sp_att_date) >= '#{newdated}'"
          session[:req_asondated] = asondated
        end
      
        if uptodated.present?
          udated = year_month_days_formatted(uptodated)
          iswhere += " AND DATE(sp_att_date) <= '#{udated}'"
          session[:req_uptodated] = uptodated
        end
  
        if report_course.present?
          iswhere += " AND mst_course_lists.id = '#{report_course}'"
          session[:req_report_course] = report_course
        end 
        
        if report_semester.present?
          iswhere += " AND sp_att_sem = '#{report_semester}'"
          session[:req_report_semester] = report_semester
        end 

        if report_club.present?
          iswhere += " AND mst_house_lists.id = '#{report_club}'"
          session[:req_report_club] = report_club
        end

        data = TrnSpecialAttendance
        .joins("LEFT JOIN mst_house_lists ON mst_house_lists.id = trn_special_attendances.sp_att_house")
        .joins("LEFT JOIN mst_course_lists ON mst_course_lists.id = trn_special_attendances.sp_att_crse")
        .select("trn_special_attendances.*, mst_house_lists.hs_house_name, mst_course_lists.crse_descp")
        .where("trn_special_attendances.sp_att_compcode = ? AND #{iswhere}", @compcodes)

          respond_to do |format|
            format.json { render json: { 'data' => data,  status: data.present? } }
            end
      end
    end
    
    private
    def generate_attendance_reports_consolidated
      report_course   = session[:req_report_course]
      report_semester = session[:req_report_semester]
      asondated       = session[:req_asondated]
      uptodated       = session[:req_uptodated]

      start_date = year_month_days_formatted(asondated)
      end_date   = year_month_days_formatted(uptodated)

      # Step 1: Base attendance query
      base_attendance = TrnAttendance
        .joins("INNER JOIN mst_subject_lists ON trn_attendances.att_subject = mst_subject_lists.id")
        .where("DATE(att_date) BETWEEN ? AND ?", start_date, end_date)
        .where("mst_subject_lists.sub_crse = ? AND mst_subject_lists.sub_sem = ?", report_course, report_semester)

      #Step 2: Join special attendance (period wise)
      # We will LEFT JOIN to check if any matching special attendance marks 'Y' for that date & period.
      data = base_attendance
        .joins("LEFT JOIN trn_special_attendances ON 
                  trn_special_attendances.sp_att_compcode = trn_attendances.att_compcode
                  AND trn_special_attendances.sp_att_fclty = trn_attendances.att_fclty
                  AND trn_special_attendances.sp_att_date = trn_attendances.att_date
                  AND trn_special_attendances.sp_att_std_rollno = trn_attendances.att_stdnt_code")
        .select(
          "trn_attendances.att_stdnt_code AS roll_no,
          SUM(
            CASE 
              WHEN trn_attendances.att_attnd = 'Y' THEN 1
              WHEN trn_attendances.att_attnd = 'N' 
                    AND (
                        (trn_attendances.att_period = '1' AND trn_special_attendances.sp_att_prd1 = 'Y') OR
                        (trn_attendances.att_period = '2' AND trn_special_attendances.sp_att_prd2 = 'Y') OR
                        (trn_attendances.att_period = '3' AND trn_special_attendances.sp_att_prd3 = 'Y') OR
                        (trn_attendances.att_period = '4' AND trn_special_attendances.sp_att_prd4 = 'Y') OR
                        (trn_attendances.att_period = '5' AND trn_special_attendances.sp_att_prd5 = 'Y') OR
                        (trn_attendances.att_period = '6' AND trn_special_attendances.sp_att_prd6 = 'Y') OR
                        (trn_attendances.att_period = '7' AND trn_special_attendances.sp_att_prd7 = 'Y') OR
                        (trn_attendances.att_period = '8' AND trn_special_attendances.sp_att_prd8 = 'Y')
                    )
              THEN 1
              ELSE 0
            END
          ) AS attended,
          COUNT(trn_attendances.att_attnd) AS total"
        )
        .group("trn_attendances.att_stdnt_code")

      #Step 3: Generate CSV
      CSV.generate(headers: true) do |csv|
        csv << ["S.No.", "Roll No.", "Attended", "Total", "%AGE"]
        data.each_with_index do |record, index|
          percentage = (record.attended.to_f / record.total.to_f * 100).round
          csv << [index + 1, record.roll_no, record.attended, record.total, percentage]
        end
      end
    end
   
private

def generate_attendance_reports_individual
  report_course   = session[:req_report_course]
  report_semester = session[:req_report_semester]
  asondated       = session[:req_asondated]
  uptodated       = session[:req_uptodated]
  report_type     = session[:req_report_type]

  start_date = year_month_days_formatted(asondated)
  end_date   = year_month_days_formatted(uptodated)

  iswhere = "1=1"
  iswhere += " AND DATE(att_date) >= '#{start_date}'" if start_date.present?
  iswhere += " AND DATE(att_date) <= '#{end_date}'" if end_date.present?
  iswhere += " AND mst_subject_lists.sub_crse = '#{report_course}'" if report_course.present?
  iswhere += " AND mst_subject_lists.sub_sem = '#{report_semester}'" if report_semester.present?

  months = TrnAttendance
    .joins("INNER JOIN mst_subject_lists ON trn_attendances.att_subject = mst_subject_lists.id")
    .where(iswhere)
    .pluck(Arel.sql("DISTINCT DATE_FORMAT(att_date, '%b-%Y')"))
    .sort_by { |m| Date.strptime(m, '%b-%Y') }

  data = TrnAttendance
    .joins("INNER JOIN mst_subject_lists ON trn_attendances.att_subject = mst_subject_lists.id")
    .joins("INNER JOIN mst_students ON trn_attendances.att_stdnt_code = mst_students.stdnt_reg_no")
    .select("
      att_stdnt_code AS roll_no,
      CONCAT(mst_students.stdnt_fname, ' ', mst_students.stdnt_lname) AS name,
      mst_subject_lists.sub_code AS subject_code,
      mst_subject_lists.sub_name AS subject_name,
      DATE_FORMAT(att_date, '%b-%Y') AS month,
      SUM(CASE WHEN att_attnd = 'Y' THEN 1 ELSE 0 END) AS attended,
      SUM(CASE WHEN att_attnd = 'Y' AND att_sp = 'SP' THEN 1 ELSE 0 END) AS special_attended,
      COUNT(att_attnd) AS total_classes
    ")
    .where(iswhere)
    .group("att_stdnt_code, subject_code, month")
    .order("roll_no, subject_code, month")

  formatted_data = format_attendance_data(data, months)

  CSV.generate(headers: true) do |csv|
    subjects = data.map { |d| [d.subject_code, d.subject_name] }.uniq.to_h
    headers = ["S.No.", "Roll No.", "Name"] +
              subjects.map { |code, name| months.map { |m| "#{name}-#{code} (#{m})" } }.flatten +
              ["Total Attended", "Total Classes", "Attendance Percentage", "Special Attendance(Already Included in Total)"]
    csv << headers

    formatted_data.each do |student|
      row = [student["S.No."], student["Roll No."], student["Name"]]
      subjects.each do |code, _name|
        months.each do |month|
          attendance_value = student.dig(code, month) || "0/0"
          row << "'#{attendance_value}'"
        end
      end
      row += [student["Total Attended"], student["Total Classes"], student["Attendance Percentage"], student["Special Attendance(Already Included in Total)"]]
      csv << row
    end
  end
end

def format_attendance_data(data, months)
  students = {}

  data.each do |row|
    roll_no = row.roll_no
    name = row.name
    subject = row.subject_code
    month = row.month
    attended = row.attended.to_i
    special_attended = row.special_attended.to_i
    total_classes = row.total_classes.to_i

    students[roll_no] ||= {
      "S.No." => nil,
      "Roll No." => roll_no,
      "Name" => name,
      "Total Attended" => 0,
      "Special Attendance(Already Included in Total)" => 0,
      "Total Classes" => 0,
      "Attendance Percentage" => "0%"
    }

    students[roll_no][subject] ||= Hash[months.map { |m| [m, "0/0"] }]
    students[roll_no][subject][month] = "#{attended}/#{total_classes}"

    # Update totals
    students[roll_no]["Total Attended"] += attended
    students[roll_no]["Special Attendance(Already Included in Total)"] += special_attended
    students[roll_no]["Total Classes"] += total_classes
  end

  students.each_value do |student|
    total_classes = student["Total Classes"]
    student["Attendance Percentage"] =
      total_classes > 0 ? "#{((student["Total Attended"].to_f / total_classes) * 100).round(2)}%" : "0%"
  end

  students.values.each_with_index.map do |student, index|
    student["S.No."] = index + 1
    student
  end
end
  
  private
  def generate_special_attendance_reports
    compcode       = session[:loggedUserCompCode]
    course_id      = session[:req_report_course]
    semester       = session[:req_report_semester]
    from_date      = year_month_days_formatted(session[:req_asondated])
    to_date        = year_month_days_formatted(session[:req_uptodated])
    house_id       = session[:req_report_club]
  
    records = TrnSpecialAttendance
                .joins("LEFT JOIN mst_house_lists ON mst_house_lists.id = trn_special_attendances.sp_att_house")
                .joins("LEFT JOIN mst_course_lists ON mst_course_lists.id = trn_special_attendances.sp_att_crse")
                .where("trn_special_attendances.sp_att_compcode = ?", compcode)
                .where("DATE(sp_att_date) BETWEEN ? AND ?", from_date, to_date)
                .where("sp_att_crse = ?", course_id)
                .where("sp_att_sem = ?", semester)
                .where("sp_att_house = ?", house_id)
                .select("trn_special_attendances.*, mst_house_lists.hs_house_name, mst_course_lists.crse_descp")
                .order("sp_att_date ASC")
  
    return "" if records.blank?
  
    # Collect unique dates for columns
    all_dates = records.map(&:sp_att_date).uniq.sort
    csv_data = CSV.generate(headers: true) do |csv|
      # Header Row
      headers = ["S.No", "Roll No", "Student Name"]
      headers += all_dates.map { |d| d.strftime("%d-%b") }
      csv << headers
  
      # Group by student (roll no)
      grouped = records.group_by(&:sp_att_std_rollno)
      serial = 1
      
      grouped.each do |roll_no, entries|
        student_name = entries.first.sp_att_std_name.strip
        row = [serial, roll_no, student_name]
      
        all_dates.each do |date|
          entry = entries.find { |e| e.sp_att_date == date }
          if entry.present?
            # Count how many periods are marked 'Y'
            period_count = %w[sp_att_prd1 sp_att_prd2 sp_att_prd3 sp_att_prd4 sp_att_prd5 sp_att_prd6 sp_att_prd7 sp_att_prd8]
                            .count { |prd| entry.send(prd) == 'Y' }
            row << period_count
          else
            row << "-"
          end
        end
      
        csv << row
        serial += 1
      end
      
    end
  
    return csv_data
  end
  
  
end
