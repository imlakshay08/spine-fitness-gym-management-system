class InventoryOutletController < ApplicationController
    before_action      :require_login
    skip_before_action :verify_authenticity_token, :only=> [:index,:ajax_process]
    include ErpModule::Common
    helper_method :formatted_date,:get_user_city_logged_detail,:get_outlet_reference,:get_payment_transaction_detail

    def index
        @compcodes  = session[:loggedUserCompCode]
        @cdate      = Time.now.to_date
        month_number =  Time.now.month
        month_begin  =  Date.new(Date.today.year, month_number)
        begdate      =  Date.parse(month_begin.to_s)
        @nbegindate  =  begdate.strftime('%d-%b-%Y')
        month_ending =  month_begin.end_of_month
        endingdate   =  Date.parse(month_ending.to_s)
        @enddate     =  endingdate.strftime('%d-%b-%Y')
        @outletlist = get_outlet_list()
        printcontroll   = "1_prt_excel_outlet_list"
        @printpath      = inventory_outlet_path(printcontroll,:format=>"csv")
        if params[:id].to_s.present?
          types         = session[:req_report_type]
          if types == 'DET'
            filename = "inventory_detail_report"
          elsif types == 'SUM'
            filename = "inventory_summary_report"
          end
            
          docs = params[:id].to_s.split("_")
          if docs[1].to_s == 'prt'
            if types == 'DET'
                send_data generate_irm_details_csv, filename: "#{filename}-#{Date.today}.csv"
            elsif types == 'SUM'
                send_data generate_irm_summary_csv, filename: "#{filename}-#{Date.today}.csv"
            end
            return
        end
      end
    end
        
    
    def ajax_process
      @compcodes  = session[:loggedUserCompCode]
      if params[:identity]!=nil && params[:identity]!='' && params[:identity] == 'Y'
        check_detail_summary() 
         return
      end
   
    end
    def referesh_inventory_outlet
         
      session[:req_asondated]  = nil
      session[:req_uptodated] = nil
      session[:req_my_outletname] = nil
      session[:req_report_type]=nil
      
        redirect_to "#{root_url}inventory_outlet"
  
  end
    def check_detail_summary
      asondated = params[:asondated]
      uptodated = params[:uptodated]
      my_outletname  = params[:my_outletname]
      report_type = params[:report_type]

      session[:req_asondated]  = nil
      session[:req_uptodated] = nil
      session[:req_my_outletname] = nil
      session[:req_report_type]=nil
      
      iswhere        = "id>0"
    if report_type !=nil && report_type !='' && report_type =='DET'
        session[:req_report_type]  = report_type

    elsif report_type !=nil && report_type !='' && report_type =='SUM'
         session[:req_report_type]  = report_type

    end
    if asondated != nil && asondated != ''    
       newdated  = year_month_days_formatted(asondated)
       iswhere   += " AND DATE(irm_dated) >= '#{newdated}'"
       session[:req_asondated] = asondated
   end
   if uptodated !=nil && uptodated !=''
       udated    = year_month_days_formatted(uptodated)
       iswhere   += " AND DATE(irm_dated) <= '#{udated}'"
       session[:req_uptodated] = uptodated
   end   
   if my_outletname !=nil && my_outletname !=''
    iswhere +=" AND ( irm_number LIKE '%#{filter_search}%' OR irm_outletname LIKE '%#{filter_search}%' OR irm_outletrefno LIKE '%#{filter_search}%' OR irm_outletid LIKE '%#{filter_search}%')"
      @my_outletname       = my_outletname
      session[:req_my_outletname] = my_outletname
  end 


      if report_type == 'DET'
        data = TrnIssueReturnMaterial.select("id"
        ).where(iswhere)
        .paginate(page: @pages, per_page: 10)
        .order('irm_dated', 'irm_outletname')
      else
        data = TrnIssueReturnMaterial.select("id"
        ).where(iswhere)
        .group('irm_dated', 'irm_outletid', 'irm_outletname')
        .paginate(page: @pages, per_page: 10)
        .order('irm_dated', 'irm_outletname')
      end
      isfalse = false
      if data.length >0
          isfalse = true
      end
      respond_to do |format|
        format.json { render json: { 'data' => data, status: data.present? } }
        format.csv { send_data generate_attendance_reports_consolidated, filename: "attendance_report.csv" }
      end
       
    end

    def get_outlet_list
      @compcodes = session[:loggedUserCompCode]
      if params[:page].to_i >0
        pages = params[:page]
      else
        pages = 1
      end 
      if params[:asondated] !=nil && params[:asondated] !=''
          session[:req_asondated] = params[:asondated]
      end
      if  params[:uptodated] !=nil && params[:uptodated]!=''
          session[:req_uptodated] = params[:uptodated]
      end
      if  params[:my_outletname] !=nil && params[:my_outletname] !=''
        session[:req_my_outletname] = params[:my_outletname]
      end
      if params[:server_request]!=nil && params[:server_request]!= '' 
        session[:req_asondated] = nil          
        session[:req_my_outletname] = nil
     end
      asondated      = params[:asondated] !=nil && params[:asondated] !='' ? params[:asondated] : session[:req_asondated]
      uptodated      = params[:uptodated] !=nil && params[:uptodated] !='' ? params[:uptodated] : session[:req_uptodated]
      filter_search = params[:my_outletname] !=nil && params[:my_outletname] != '' ? params[:my_outletname].to_s.strip : session[:req_my_outletname].to_s.strip       
      iswhere        = "id>0"
    if asondated != nil && asondated != ''    
       newdated  = year_month_days_formatted(asondated)
       iswhere   += " AND DATE(irm_dated) >= '#{newdated}'"
       @asondated = asondated
   else
       newstartdt  = year_month_days_formatted(@nbegindate)
       iswhere += " AND DATE(irm_dated) >= '#{newstartdt}'"
   end
   if uptodated !=nil && uptodated !=''
       udated    = year_month_days_formatted(uptodated)
       iswhere   += " AND DATE(irm_dated) <= '#{udated}'"
       @uptodated = uptodated
   else
       newsenddt  = year_month_days_formatted(@cdate)
       iswhere += " AND DATE(irm_dated) <= '#{newsenddt}'"
   end   
   if filter_search !=nil && filter_search !=''
    iswhere +=" AND ( irm_number LIKE '%#{filter_search}%' OR irm_outletname LIKE '%#{filter_search}%' OR irm_outletrefno LIKE '%#{filter_search}%' OR irm_outletid LIKE '%#{filter_search}%')"
      @my_outletname       = filter_search
      session[:req_my_outletname] = filter_search
  end 

      data = TrnIssueReturnMaterial.select('irm_dated, irm_outletid, irm_outletname, irm_createdby,irm_upid,irm_image,irm_imgpath,irm_number,irm_totalbalance, irm_insttime, irm_type,
                      SUM(CASE WHEN irm_type = "I" THEN irm_no_of_stick ELSE 0 END) AS total_issues, 
                      SUM(CASE WHEN irm_type = "R" THEN irm_no_stick_consume ELSE 0 END) AS total_returns')
             .where(iswhere)
             .paginate(:page =>@pages,:per_page => 10)
             .group('irm_dated', 'irm_outletid', 'irm_outletname')
             .order('irm_dated', 'irm_outletname')
    
      return data
    end

   

   private
   def generate_irm_details_csv
     asondated      = session[:req_asondated]
     uptodated      = session[:req_uptodated]
     my_outletname  = filter_search = session[:req_my_outletname]
     report_type    = session[:req_report_type]
     iswhere = "id>0"
   
     if asondated.present?
       newdated = year_month_days_formatted(asondated)
       iswhere += " AND DATE(irm_dated) >= '#{newdated}'"
     end
   
     if uptodated.present?
       udated = year_month_days_formatted(uptodated)
       iswhere += " AND DATE(irm_dated) <= '#{udated}'"
     end
   
     if my_outletname.present?
       iswhere +=" AND ( irm_number LIKE '%#{filter_search}%' OR irm_outletname LIKE '%#{filter_search}%' OR irm_outletrefno LIKE '%#{filter_search}%' OR irm_outletid LIKE '%#{filter_search}%')"
     end
   
     data = TrnIssueReturnMaterial.select(
       'trn_issue_return_materials.irm_dated',
       'trn_issue_return_materials.irm_outletid',
       'trn_issue_return_materials.irm_outletname',
       'trn_issue_return_materials.irm_upid',
       'trn_issue_return_materials.irm_image',
       'trn_issue_return_materials.irm_imgpath',
       '"" AS pse_id',
       '"" AS pse_name',
       '"" AS referenc_id',  
       '"" AS city',  
       '"" AS address', 
       '"" AS transid',
       '"" AS transmessage',
       '"" AS transamt',
       'irm_no_of_stick AS total_issues',
       'irm_no_stick_consume AS total_returns',
       'irm_createdby','irm_insttime','irm_totalbalance',
       'CASE WHEN irm_type = "I" THEN "Issue" ELSE "Return" END as types'
     ).where(iswhere)
      .order('trn_issue_return_materials.irm_dated', 'trn_issue_return_materials.irm_outletid')
   
     ardata = []
     overall_total_issues = 0
     overall_total_returns = 0
   
     if data.present?
       data.each do |record|
         objsuser = get_user_city_logged_detail(record.irm_createdby)
         if objsuser
           record.pse_id = objsuser.username
           record.pse_name = objsuser.firstname
         end
         referncobj = get_outlet_reference(record.irm_outletid)
         if referncobj
             record.referenc_id = referncobj.lod_outlet_refno
             record.city      = referncobj.lod_city
             record.address   = referncobj.lod_area
         end
          paymentdt = get_payment_transaction_detail(record.irm_outletid)
                    if paymentdt
                        transid = paymentdt.pmt_transactno
                        transmessage = paymentdt.pmt_message
                        transamt = paymentdt.pmt_amts
                    end
         ardata.push(record)
   
         overall_total_issues += record.total_issues.to_f
         overall_total_returns += record.total_returns.to_f
       end
     end
   
     CSV.generate(headers: true) do |csv|
       csv << ['Entry Date', 'Entry Time', 'PSE Id', 'PSE Name', 'City', 'Outlet Reference ID', 'Outlet Name', 'Address', 'UPI Id', 'UPI Image', 'Issues', 'Returns', 'Balance', 'UPI Transaction ID', 'Transaction Status', 'Amt']
       
       ardata.each do |record|
         upiimage = record.irm_image.present? ? "https://rrpoutlets.com/images/consumers/#{record.irm_imgpath}/#{record.irm_image}" : "No Image"
         
         csv << [
           record.irm_dated,
           record.irm_insttime,
           record.pse_id,
           record.pse_name,
           record.city,
           record.referenc_id,
           record.irm_outletname.split('-')[1]&.strip,
           record.address,
           record.irm_upid,
           upiimage,
           record.total_issues,
           record.total_returns,
           record.irm_totalbalance,
           record.transid,
           record.transmessage,
           record.transamt
         ]
       end
   
       if ardata.present?
         csv << []
         csv << ['TOTAL', '', '', '', '', '', '', '', '', '', overall_total_issues, overall_total_returns, '','']
       end
     end
   end

   private
   def generate_irm_summary_csv
     asondated     = session[:req_asondated]
     uptodated     = session[:req_uptodated]
     my_outletname = filter_search = session[:req_my_outletname]
     report_type   = session[:req_report_type]

     iswhere = "id>0"
   
     if asondated.present?
       newdated = year_month_days_formatted(asondated)
       iswhere += " AND DATE(irm_dated) >= '#{newdated}'"
     end
   
     if uptodated.present?
       udated = year_month_days_formatted(uptodated)
       iswhere += " AND DATE(irm_dated) <= '#{udated}'"
     end
   
     if my_outletname.present?
       iswhere +=" AND ( irm_number LIKE '%#{filter_search}%' OR irm_outletname LIKE '%#{filter_search}%' OR irm_outletrefno LIKE '%#{filter_search}%' OR irm_outletid LIKE '%#{filter_search}%')"
     end
   
     data = TrnIssueReturnMaterial.select(
       'irm_dated',
       'irm_outletid',
       'irm_outletname',
       'irm_createdby',
       '"" AS pse_id',
       '"" AS pse_name',
       '"" AS referenc_id',
       'SUM(CASE WHEN irm_type = "I" THEN irm_no_of_stick ELSE 0 END) AS total_issues',
       'SUM(CASE WHEN irm_type = "R" THEN irm_no_stick_consume ELSE 0 END) AS total_returns',
        'CASE WHEN irm_type = "I" THEN "Issue" ELSE "Return" END as types'
     ).where(iswhere)
      .group('irm_dated', 'irm_outletid')
      .order('irm_dated', 'irm_outletname')
        
        ardata = []
     overall_total_issues = 0
     overall_total_returns = 0
   
     CSV.generate(headers: true) do |csv|
       csv << ['Date', 'PSE Id', 'PSE Name','Reference ID', 'Outlet Name', 'Type','Issues', 'Returns', 'Balance']
   
       if data.present?
         data.each do |record|
         objsuser = get_user_city_logged_detail(record.irm_createdby)
         if objsuser
           record.pse_id = objsuser.username
           record.pse_name = objsuser.firstname
         end
         referncobj = get_outlet_reference(record.irm_outletid)
         if referncobj
             record.referenc_id = referncobj.lod_outlet_refno
         end
         ardata.push(record)
         
           total_issues = record.total_issues.to_f
           total_returns = record.total_returns.to_f
           balance = total_issues - total_returns
   
           overall_total_issues += total_issues
           overall_total_returns += total_returns
   
           csv << [
             record.irm_dated,
             record.pse_id,
             record.pse_name,
             record.referenc_id,
             record.irm_outletname.split('-')[1]&.strip,
             record.types,
             total_issues,
             total_returns,
             balance
           ]
         end
   
         csv << []
         csv << ['TOTAL', '', '', '', '','', overall_total_issues, overall_total_returns, overall_total_issues - overall_total_returns]
       end
     end
   end
    
end
