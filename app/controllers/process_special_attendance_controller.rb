class ProcessSpecialAttendanceController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct  
    def index
        @compcodes   = session[:loggedUserCompCode] 
        month_number =  Time.now.month
        month_begin  =  Date.new(Date.today.year, month_number)
        begdate      =  Date.parse(month_begin.to_s)
        @nbegindate  =  begdate.strftime('%d-%b-%Y')
        month_ending =  month_begin.end_of_month
        endingdate   =  Date.parse(month_ending.to_s)
        @enddate     =  endingdate.strftime('%d-%b-%Y')

    @MonthsList = []
    (1..12).each do |m|
        @MonthsList.push([Date::MONTHNAMES[m], m])  
    end

    @YearsList = []
    current_year = Date.today.year
    (current_year-5..current_year+1).each do |y|
        @YearsList.push(y)
    end

    
    end

     def ajax_process
         @compcodes      = session[:loggedUserCompCode] 
        if params[:identity]!=nil && params[:identity]!= '' && params[:identity] == 'SPECIAL'
            process_special_attendance();
            return
        end 
    end

    def process_special_attendance
        @compcodes = session[:loggedUserCompCode]
        month = params[:psa_month].to_i
        year  = params[:psa_year].present? ? params[:psa_year].to_i : Date.today.year

        begdate = Date.new(year, month, 1)
        enddate = begdate.end_of_month

        special_records = TrnSpecialAttendance.where(
            sp_att_compcode: @compcodes,
            sp_att_date: begdate..enddate
        )

        updated_count = 0

        special_records.find_each(batch_size: 200) do |sp|
            student_code = sp.sp_att_std_rollno.to_s.strip
            sp_date      = sp.sp_att_date

            # Only fetch absent records once per student & date
            att_records = TrnAttendance.where(
            att_compcode: @compcodes,
            att_stdnt_code: student_code,
            att_date: sp_date,
            att_attnd: 'N'
            ).index_by(&:att_period)

            # If no absents ? skip
            next if att_records.empty?

            updates = []

            (1..8).each do |prd|
            if sp.send("sp_att_prd#{prd}").to_s.upcase == 'Y'
                att = att_records[prd.to_s]
                next unless att

                updates << att.id
            end
            end

            if updates.any?
            TrnAttendance.where(id: updates).update_all(
                att_attnd: 'Y',
                att_sp: 'SP',
                updated_at: Time.now
            )
            updated_count += updates.count
            end
        end

        render json: {
            status: 'success',
            message: "#{updated_count} attendance records updated using special attendance faster"
        }
        end

end
