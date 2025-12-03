class FacultyAttendanceReportController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    def index
        @compcodes   = session[:loggedUserCompCode] 
        month_number =  Time.now.month
        month_begin  =  Date.new(Date.today.year, month_number)
        begdate      =  Date.parse(month_begin.to_s)
        @nbegindate  =  begdate.strftime('%d-%b-%Y')
        month_ending =  month_begin.end_of_month
        endingdate   =  Date.parse(month_ending.to_s)
        @enddate     =  endingdate.strftime('%d-%b-%Y')
        @CourseList     = MstCourseList.where("crse_compcode =? AND crse_code != ''  ", @compcodes)
        @SubjectList    = MstSubjectList.where("sub_compcode =? AND sub_name != ''  ", @compcodes)
        @HouseList = MstHouseList.where("hs_compcode =? AND hs_house_name != ''  ",@compcodes)
        @printexcelPath =  "faculty_attendance_report/1_excel_prt_report.pdf"

    @MonthsList = []
    (1..12).each do |m|
        @MonthsList.push([Date::MONTHNAMES[m], m])   # ["January",1], ["February",2] ...
    end

    @YearsList = []
    current_year = Date.today.year
    (current_year-5..current_year+1).each do |y|
        @YearsList.push(y)
    end
    
        if params[:id] != nil && params[:id] != ''
           
        @compDetail   =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        docsid        = params[:id].to_s.split("_")
        rooturl       = "#{root_url}"
        @excelObjx = nil   
          
            if docsid[1] == 'excel' && docsid[2].to_s.strip == 'prt'
                       @rdata    = print_contract_detail_excel()
                        if @excelObjx
                            $excelitems = @rdata                       
                            send_data TrnAttendance.faculty_attendance_report, :filename=> "faculty_attendance_report_#{Date.today}.csv"
                            return
                        end
            end
          end
          
    end


    def ajax_process
         @compcodes      = session[:loggedUserCompCode] 
        if params[:identity]!=nil && params[:identity]!= '' && params[:identity] == 'PRNTCONTRACT'
            get_attendance_details();
            return
        end 
    end

    def get_attendance_details
        @compcodes   = session[:loggedUserCompCode] 
        isflags      = false
        message      = ""

        report_month    = params[:report_month]
        report_year     = params[:report_year]
        report_course   = params[:report_course]
        report_semester = params[:report_semester]
        report_subject  = params[:report_subject]

        if report_month.blank?
            message = "Month is required"
        elsif report_year.blank?
            message = "Year is required"
        elsif report_course.blank?
            message = "Course is required"
        elsif report_semester.blank?
            message = "Semester is required"
        elsif report_subject.blank?
            message = "Subject is required"
        else
            session[:sess_report_month]    = report_month
            session[:sess_report_year]     = report_year
            session[:sess_report_course]   = report_course
            session[:sess_report_semester] = report_semester
            session[:sess_report_subject]  = report_subject
            isflags = true
        end

        respond_to do |format|
            format.json { render :json => { "message"=>message,:status=>isflags} }
        end
    end
        
def print_contract_detail_excel
    @compcodes      = session[:loggedUserCompCode]
    report_month    = session[:sess_report_month]
    report_year     = session[:sess_report_year]
    report_course   = session[:sess_report_course]
    report_semester = session[:sess_report_semester]
    report_subject  = session[:sess_report_subject]

    weekday_map = {
    "MON" => "MON",
    "TUE" => "TUES",
    "WED" => "WED",
    "THU" => "THURS",
    "FRI" => "FRI",
    "SAT" => "SAT",
    "SUN" => "SUN"
    }

    @excelObjx = []
    if report_month.to_i > 0 && report_year.to_i > 0 && report_subject.to_i > 0
        begdate = Date.new(report_year.to_i, report_month.to_i, 1)
        enddate = begdate.end_of_month

        attendances = TrnAttendance.where("att_compcode = ? AND att_subject = ? AND att_date BETWEEN ? AND ?", @compcodes, report_subject, begdate, enddate)

        subject = MstSubjectList.where("sub_compcode = ? AND id = ?", @compcodes, report_subject).first
        subname = subject ? subject.sub_name : ""

        month_year = Date.new(report_year.to_i, report_month.to_i, 1).strftime("%B-%Y")

        dateslist = []
        attendances.each do |att|
            dateslist.push(att.att_date) if !dateslist.include?(att.att_date)
        end
        dateslist = dateslist.sort

        groups = []
        attendances.each do |att|
            groups.push(att.att_grp) if !groups.include?(att.att_grp)
        end
        groups = groups.sort

        finaldata = []
        groups.each do |grp|
            finaldata.push([ "Group #{grp}" ])  

            students = []
            attendances.each do |att|
                if att.att_grp == grp && !students.include?(att.att_stdnt_code)
                    students.push(att.att_stdnt_code)
                end
            end
            students = students.sort

            # ?? Calculate total periods happened for this subject & group in month
            total_periods_happened = 0
            (begdate..enddate).each do |day|
                weekday =  weekday_map[day.strftime("%a").upcase]   # MON, TUES, WED ...
                timetable = MstTimeTable.where("tt_compcode = ? AND tt_year = ? AND tt_subject = ? AND tt_group = ? AND tt_day = ?", 
                                               @compcodes, report_year, report_subject, grp, weekday)
                total_periods_happened += timetable.count
            end

            students.each do |stdid|
                row = []
                student = MstStudent.where("stdnt_compcode = ? AND stdnt_reg_no = ?", @compcodes, stdid).first
                stdname = student ? student.stdnt_fname.to_s + " " + student.stdnt_lname.to_s : ""

                row.push(stdid)    # NCHM RI No
                row.push(stdname)  # Student Name

                totaldayspresent = 0
                totalperiodspresent = 0

                dateslist.each do |dt|
                    prescount = 0
                    abscount  = 0

                    statusarr = []
                    attendances.each do |st|
                        if st.att_stdnt_code.to_s == stdid.to_s && st.att_date == dt
                            statusarr.push(st)
                        end
                    end

                    statusarr.each do |st|
                        if st.att_attnd.to_s == 'Y'
                            prescount += 1
                        else
                            abscount  += 1
                        end
                    end

                    if prescount > 0
                        row.push("P")
                        totaldayspresent += 1
                    elsif abscount > 0
                        row.push("A")
                    else
                        row.push("A")
                    end

                    totalperiodspresent += prescount
                end

                row.push(totaldayspresent)          # Days(P)
                row.push(totalperiodspresent)       # Periods(P)
                row.push(total_periods_happened)    # ?? Total Periods Happened
                finaldata.push(row)
            end

            finaldata.push([])
        end

        @excelObjx = [subname, month_year, dateslist, finaldata]
    end
    return @excelObjx
end

end
