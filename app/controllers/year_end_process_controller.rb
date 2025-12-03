class YearEndProcessController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date
    def index
        @compcodes   = session[:loggedUserCompCode]
         if params[:id].to_i>0
            @yearEndProcess=TrnYearEndProcess.where("yep_compcode = ? AND id = ?",@compcodes,params[:id]).first
        end
        @yearEndProcess = TrnYearEndProcess.where("yep_compcode = ?", @compcodes)
    end

    def ajax_process
       @compcodes   = session[:loggedUserCompCode]
        if params[:identity] != nil && params[:identity] != '' && params[:identity] == 'YEARENDPROCESS'
          run_year_end_process();
          return
        end
    end

    def run_year_end_process
    @compcodes = session[:loggedUserCompCode]
    endprocess_year = params[:endprocess_year]
    isFlags = false
    message = ""

    # Check if year-end process already done for this year
    chkprocess = TrnYearEndProcess.where("yep_compcode=? AND yep_year=?", @compcodes, endprocess_year)
    if chkprocess.length > 0
        message = "Year-end process already completed for year #{endprocess_year}"
        render json: { status: false, message: message }
        return
    end

    @course = MstCourseList.where("crse_compcode=? ", @compcodes)

    if @course.length > 0
        @course.each do |cr|
        crseid     = cr.id.to_s
        crsecode   = cr.crse_code
        duration   = cr.crse_duration
        is_one_year = duration.strip.downcase == '1 year'
        max_sem    = 0

        # Calculate max semester only for multi-year courses
        unless is_one_year
            duration_year = duration.split(" ").first.to_i
            max_sem = duration_year * 2
        end

        # Fetch active students in that course
        stdnts = MstStdntGenDtl.where("stdnt_gn_compcode=? AND stdnt_gn_status=? AND stdnt_gn_code IN 
            (SELECT stdnt_dtl_code FROM mst_student_dtls WHERE stdnt_dtl_crse=?)", @compcodes, 'A', crseid)

        if stdnts.length > 0
            stdnts.each do |std|
            cur_sem = std.stdnt_gn_cur_sem.to_i
            new_sem = cur_sem  # default is same semester

            if is_one_year
                std.update(stdnt_gn_status: 'PO', stdnt_gn_poy: endprocess_year)
            else
                if cur_sem < max_sem
                new_sem = cur_sem + 1
                std.update(stdnt_gn_cur_sem: new_sem)
                else
                std.update(stdnt_gn_status: 'PO', stdnt_gn_poy: endprocess_year)
                end
            end

            TrnYearEndProcess.create(
                yep_compcode: @compcodes,
                yep_course: crseid,
                yep_old_semester: cur_sem.to_s,
                yep_new_semester: new_sem.to_s,
                yep_stdnt_rollno: std.stdnt_gn_code,
                yep_year: endprocess_year
            )

            isFlags = true
            end
        end
        end
    end

    if isFlags
        message = "Year-end process successfully completed for year #{endprocess_year}"
        render json: { status: true, message: message }
    else
        message = "No active students found to process."
        render json: { status: false, message: message }
    end
    end



end
