class SpecialAttendanceController < ApplicationController
  before_action :require_login
  skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
  helper_method :currency_formatted,:year_month_days_formatted,:formatted_date
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
      @CourseList = MstCourseList.where(["crse_compcode =?",@compcodes]) 
      @HouseList = MstHouseList.where("hs_compcode =? AND hs_house_name != ''  ",@compcodes)
      @Listsemester = []
      @CourseList.each do |course|
        duration = course.crse_duration
        @Listsemester += get_semester_list(duration)
      end
      @Listsemester.uniq!
      @special_attend=nil
      if params[:id].to_i>0
          @special_attend=TrnSpecialAttendance.where("sp_att_compcode=? AND id=?",@compcodes,params[:id]).first
          @selected_semester = @subject.sub_sem if @subject.present?   

      end  
      @special_attendance=TrnSpecialAttendance.where("sp_att_compcode=? AND id=?",@compcodes,params[:id])
      printcontroll   = "1_prt_special_attendance"
      @printpath      = special_attendance_path(printcontroll,:format=>"csv")
      if params[:id].to_s.present?
        filename = "special_attendance_report"
          docs = params[:id].to_s.split("_")
          if docs[1].to_s == 'prt'
              send_data generate_special_attendance_csv, filename: "#{filename}-#{Date.today}.csv"
            return
          end
      end
  end

  def ajax_process
      @compcodes      = session[:loggedUserCompCode] 
      if params[:identity] != nil && params[:identity] != '' && params[:identity] == 'SEMESTER'
          get_semesters()
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
      elsif params[:identity]!=nil && params[:identity]!='' && params[:identity] == 'Y'
          check_special_attendance() 
          return
      end
  end

  def create
  end
    
  private
  def save_student_attendnce
    compcodes = session[:loggedUserCompCode]
    course = params[:sp_att_crse]
    faculty   = params[:sp_att_fclty]
    house = params[:sp_att_house]
    period = params[:sp_att_prd]
    semester = params[:sp_att_sem]
    date = params[:sp_att_date]
    activity   = params[:sp_att_actvty]
    group = params[:sp_att_grp]
    studentd_name = params[:sp_att_std_name]
    rollno = params[:sp_att_std_rollno]
    footerid  = params[:specialAttendId] !=nil && params[:specialAttendId] !='' ? params[:specialAttendId] : 0
    isFlags   = true
    message   = ""

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
                  end
           
    end     
    @adspecialattend = get_special_attendnc_information(compcodes, faculty, course, house, period, semester)
  vhtml   = render_to_string :template  => 'special_attendance/view_special_attndnc',:layout => false, :locals => { :adspecialattend => @adspecialattend}
  respond_to do |format|
    format.json { render :json => { 'data'=>vhtml,"message"=>message,:status=>isFlags} }
  end
  end

  private
  def process_qualification(sp_att_fclty)
     compcodes             = session[:loggedUserCompCode]
     sp_att_fclty          = params[:sp_att_fclty] !=nil && params[:sp_att_fclty]!='' ? params[:sp_att_fclty] : ''
     sp_att_date   = params[:sp_att_date] !=nil && params[:sp_att_date] !='' ? params[:sp_att_date] : ''
     sp_att_crse         = params[:sp_att_crse] !=nil && params[:sp_att_crse] !='' ? params[:sp_att_crse] : ''
     sp_att_house       = params[:sp_att_house] !=nil && params[:sp_att_house] !='' ? params[:sp_att_house] : ''
     sp_att_prd          = params[:sp_att_prd] !=nil && params[:sp_att_prd] !='' ? params[:sp_att_prd] : ''
     sp_att_sem        = params[:sp_att_sem] !=nil && params[:sp_att_sem] !='' ? params[:sp_att_sem] : ''
     sp_att_actvty        = params[:sp_att_actvty] !=nil && params[:sp_att_actvty] !='' ? params[:sp_att_actvty] : ''
     sp_att_grp        = params[:sp_att_grp] !=nil && params[:sp_att_grp] !='' ? params[:sp_att_grp] : ''
     sp_att_std_name        = params[:sp_att_std_name] !=nil && params[:sp_att_std_name] !='' ? params[:sp_att_std_name] : ''
     sp_att_std_rollno        = params[:sp_att_std_rollno] !=nil && params[:sp_att_std_rollno] !='' ? params[:sp_att_std_rollno] : ''
     footerid              = params[:specialAttendId] !=nil && params[:specialAttendId] !='' ? params[:specialAttendId] : 0

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
           process_save_qualification(compcodes,sp_att_fclty,sp_att_date,sp_att_crse,sp_att_house,sp_att_prd,sp_att_sem,sp_att_actvty,sp_att_grp,sp_att_std_name,sp_att_std_rollno,footerid)
           counts = 1;
       end
       return counts;

end

  private
  def process_save_qualification(sp_att_compcode,sp_att_fclty,sp_att_date,sp_att_crse,sp_att_house,sp_att_prd,sp_att_sem,sp_att_actvty,sp_att_grp,sp_att_std_name,sp_att_std_rollno,footerid)
      mstseuobj =   TrnSpecialAttendance.where("sp_att_compcode =? AND id = ?",sp_att_compcode,footerid).first
      if mstseuobj
        mstseuobj.update(:sp_att_fclty=>sp_att_fclty,:sp_att_date=>sp_att_date,:sp_att_crse=>sp_att_crse,:sp_att_house=>sp_att_house,:sp_att_prd=>sp_att_prd,:sp_att_sem=>sp_att_sem,:sp_att_actvty=>sp_att_actvty,:sp_att_grp=>sp_att_grp,:sp_att_std_name=>sp_att_std_name,:sp_att_std_rollno=>sp_att_std_rollno)
          ## execute message if required
      else

          mstsvqlobj = TrnSpecialAttendance.new(:sp_att_compcode=>sp_att_compcode,:sp_att_fclty=>sp_att_fclty,:sp_att_date=>sp_att_date,:sp_att_crse=>sp_att_crse,:sp_att_house=>sp_att_house,:sp_att_prd=>sp_att_prd,:sp_att_sem=>sp_att_sem,:sp_att_actvty=>sp_att_actvty,:sp_att_grp=>sp_att_grp,:sp_att_std_name=>sp_att_std_name,:sp_att_std_rollno=>sp_att_std_rollno)
          if mstsvqlobj.save
              ## execute message if required
          end
      end
  end

  private
  def search_student_detail_listed
    compcodes = session[:loggedUserCompCode]
    requesttype = params[:requesttype]
    sp_att_std_rollno = params[:sp_att_std_rollno].to_s.strip.upcase
    sp_att_std_name = params[:sp_att_std_name].to_s.strip
    isFlags = false
    sewdobj = nil
  
    isselect = "CONCAT(stdnt_fname, ' ', stdnt_lname) AS employeename, stdnt_reg_no AS employeecode"
  
    if requesttype == 'CODE'
      sewdobj = MstStudent.select(isselect)
                          .where('stdnt_compcode = ? AND UPPER(stdnt_reg_no) = ?', compcodes, sp_att_std_rollno)
                          .first
      isFlags = sewdobj.present?
    else
      sewdobj = MstStudent.select(isselect)
                          .where('stdnt_compcode = ? AND (stdnt_fname LIKE ? OR stdnt_lname LIKE ?)', compcodes, "%#{sp_att_std_name}%", "%#{sp_att_std_name}%")
                          .order('stdnt_fname ASC')
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
  def get_semesters
      @compcodes = session[:loggedUserCompCode]
      sp_att_crse = params[:sp_att_crse]
      semesters = []
      isflags = false
  
      # Use crse_code instead of id
      course = MstCourseList.select("crse_duration").where("crse_compcode = ? AND id = ?", @compcodes, sp_att_crse).first
  
      if course
        duration = course.crse_duration
        case duration
        when '6 Months'
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
    def check_special_attendance
      @compcodes  = session[:loggedUserCompCode]
      course = params[:sp_att_crse] 
      faculty   = params[:sp_att_fclty]
      house = params[:sp_att_house]
      semester = params[:sp_att_sem]
      raw_date = params[:sp_att_date]
      date = Date.strptime(raw_date, '%d-%b-%Y').strftime('%Y-%m-%d') # Convert '23-Jan-2025' to '2025-01-23'
      activity   = params[:sp_att_actvty].to_s.strip.downcase
      gruop = params[:sp_att_grp]
  
      session[:req_sp_att_crse]  = nil
      session[:req_sp_att_fclty] = nil
      session[:req_sp_att_house] = nil
      session[:req_sp_att_sem]=nil
      session[:req_sp_att_date]=nil
      session[:req_sp_att_actvty]=nil
    if course !=nil && course !=''
        session[:req_sp_att_crse]  = course
    end
    if date != nil && date != ''    
       session[:req_sp_att_date] = date
   end
   if faculty !=nil && faculty !=''
       session[:req_sp_att_fclty] = faculty
   end   
   if house !=nil && house !=''
      session[:req_sp_att_house] = house
   end 
   if semester !=nil && semester !=''
    session[:req_sp_att_sem] = semester
  end 
  if activity !=nil && activity !=''
    session[:req_sp_att_actvty] = activity
  end 

      message = ""
      vhtml=""
      isFlags = true
      @adspecialattend = TrnSpecialAttendance.where("sp_att_compcode = ? AND sp_att_date =? AND sp_att_fclty = ? AND sp_att_crse = ?  AND sp_att_house = ? AND sp_att_sem=? AND sp_att_actvty=?", @compcodes, date, faculty, course, house, semester,activity) 
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
  def generate_special_attendance_csv
    @compcodes  = session[:loggedUserCompCode]
    course      = session[:req_sp_att_crse]
    faculty     = session[:req_sp_att_fclty]
    house       = session[:req_sp_att_house]
    semester    = session[:req_sp_att_sem]
    date        = session[:req_sp_att_date]
    activity    = session[:req_sp_att_actvty]
  
    attendance_records = TrnSpecialAttendance.where(
      "sp_att_compcode = ? AND sp_att_date = ? AND sp_att_fclty = ? AND sp_att_crse = ? AND sp_att_house = ? AND sp_att_sem = ? AND sp_att_actvty = ?",
      @compcodes, date, faculty, course, house, semester, activity
    )
  
    return "" if attendance_records.empty?
  
    CSV.generate(headers: true) do |csv|
      # CSV Header
      csv << ["S.No", "Roll Number", "Student Name", "Period 1", "Period 2", "Period 3", "Period 4", "Period 5", "Period 6", "Period 7", "Period 8"]
  
      # CSV Data
      attendance_records.each_with_index do |record, index|
        csv << [
          index + 1,
          record.sp_att_std_rollno,
          record.sp_att_std_name,
          record.sp_att_prd1,
          record.sp_att_prd2,
          record.sp_att_prd3,
          record.sp_att_prd4,
          record.sp_att_prd5,
          record.sp_att_prd6,
          record.sp_att_prd7,
          record.sp_att_prd8
        ]
      end
    end
  end
end
