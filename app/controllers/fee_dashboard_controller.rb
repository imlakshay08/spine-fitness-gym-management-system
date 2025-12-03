class FeeDashboardController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct

    def index
        @compCodes   = session[:loggedUserCompCode]
        today = Date.today
        if today.month >= 4
          @financial_year = "#{today.year}-#{today.year + 1}"
        else
          @financial_year = "#{today.year - 1}-#{today.year}"
        end

        @nbegindate   = 2023
        @CourseList = MstCourseList.where(["crse_compcode =?",@compCodes]) 
        @courseSummary = get_course_wise_fee_summary
    end

    def ajax_process
      @compcodes  = session[:loggedUserCompCode]
 
      if params[:identity] != nil && params[:identity] != '' && params[:identity] == 'VIEWDEFAULTER'
        get_defaulter_listed();
        return;
     end
    end

    def fee_dashboard_refresh
      session[:req_financial_years] = nil
      session[:req_search_course]   = nil
       redirect_to "#{root_url}fee_dashboard"
    end

    

    def get_course_wise_fee_summary
      @compcodes = session[:loggedUserCompCode]
      page = params[:page].to_i > 0 ? params[:page].to_i : 1
    
    
      # if params[:server_request].present?
        session[:req_financial_years] = nil
        session[:req_search_course]   = nil
      # end
    
      # Retrieve filters from params or fallback to session
      financial_years = params[:financial_years].present? ? params[:financial_years].strip : session[:req_financial_years].to_s.strip
      search_course   = params[:search_course].present?   ? params[:search_course].strip   : session[:req_search_course].to_s.strip
    
      return [] if financial_years.blank? && search_course.blank?

      fy_start_year = financial_years.split("-").first.to_i if financial_years.present?
    
      # Store in session and assign to instance vars for view
      @financial_years = financial_years
      session[:req_financial_years] = financial_years
    
      @search_course = search_course
      session[:req_search_course] = search_course
    
      # Base query with dynamic conditions
      query = TrnFeeProcess.where(feepr_compcode: @compcodes)
      query = query.where(feepr_process_year: fy_start_year) if fy_start_year.present?
      query = query.where(feepr_course: search_course) if search_course.present?
    
      # SQL aggregation
      isselect = <<~SQL
        trn_fee_processes.*, 
        COUNT(DISTINCT feepr_rollno) AS total_students,
        COUNT(DISTINCT CASE WHEN feepr_actualfee != '' THEN feepr_rollno ELSE NULL END) AS paid_students,
        COUNT(DISTINCT CASE WHEN feepr_actualfee = '' THEN feepr_rollno ELSE NULL END) AS defaulters,
        SUM(feepr_actualfee) AS receivedamount
      SQL
    
      stdob = query
                .select(isselect)
                .group(:feepr_course, :feepr_sem)
                .order(:feepr_course)
    
      return stdob
    end
    


    def get_defaulter_listed
      @compcodes        = session[:loggedUserCompCode]
      reqtype           = params[:reqtype]
      course            = params[:course]
      sem               = params[:sem]
      financial_years   = session[:req_financial_years].to_s.strip
      fy_start_year     = financial_years.split("-").first.to_i if financial_years.present?
    
      # Start base query
      query = TrnFeeProcess.where(
        feepr_compcode: @compcodes,
        feepr_course: course,
        feepr_sem: sem,
        feepr_process_year: fy_start_year

      )
    
      # Filter by paid or unpaid depending on reqtype
      if reqtype == 'PS'
        query = query.where("feepr_actualfee IS NOT NULL AND feepr_actualfee != ''")
      else
        query = query.where("feepr_actualfee IS NULL OR feepr_actualfee = ''")
      end
    
      # Select with grouping
      isselect = "trn_fee_processes.*, SUM(feepr_fee) as feeamount, SUM(feepr_actualfee) as receivedamount"
      @defaulters = query.select(isselect).group("feepr_rollno")
    
      isFlags = true
      message = "success"
    
      vhtml = render_to_string template: 'fee_dashboard/defaulters_table', layout: false, locals: { defaulters: @defaulters }
    
      respond_to do |format|
        format.json { render json: { data: vhtml, message: message, status: isFlags } }
      end
    end
    

end
