include GlobalCodeGenerator

class IssueAmountController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    helper_method :get_course_detail,:get_latest_subscription, :check_active_subscription, :calculate_end_date, :subscription_status

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
        @issue_amount = get_issue_amount_list()
        printPath     =  "issue_amount/1_prt_issue_amount.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'issue'
              
              @issueamountdetail   = print_issue_amount()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = StockinventoryPdf.new(@issueamountdetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_issue_amount.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def add_issue_amount
        @compcodes      = session[:loggedUserCompCode]
        @issueamount = nil
        @Lastcode=generate_code(table: TrnIssueAmount, column: "ia_code", prefix: "IA", compcode: session[:loggedUserCompCode])
        @StaffList = MstStaffList.where("stf_compcode = ?",@compcodes)
        if params[:id].to_i>0
            @issueamount = TrnIssueAmount.where("ia_compcode=? AND id=?",@compcodes,params[:id]).first
         end
    end

    def staff_balance
    @compcodes = session[:loggedUserCompCode]

    @staff_balances = TrnIssueAmount
        .select("
        ia_staff_id,
        SUM(CASE WHEN ia_type = 'I' THEN ia_amount ELSE 0 END) AS total_issued,
        SUM(CASE WHEN ia_type = 'R' THEN ia_amount ELSE 0 END) AS total_returned
        ")
        .where(ia_compcode: @compcodes)
        .group(:ia_staff_id)
    end

    def referesh_issue_amount
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        isFlags = true
        redirect_to  "#{root_url}issue_amount"
    end

    def create
        @compcodes      = session[:loggedUserCompCode] 
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:ia_code].to_s.blank?
           flash[:error] =  "Code is Required"
           isFlags = false
        end
        if params[:ia_staff_id].to_s.blank?
          flash[:error] =  "Staff is Required"
          isFlags = false
        end
        if params[:ia_amount].to_s.blank?
            flash[:error] =  "Amount is Required"
            isFlags = false
        end
        if params[:ia_date].to_s.blank?
            flash[:error] =  "Date is Required"
            isFlags = false
        end
        if params[:ia_type].to_s.blank?
            flash[:error] =  "Type is Required"
            isFlags = false
        end
        
        if isFlags && params[:ia_type].to_s == 'R'
        staff_id     = params[:ia_staff_id]
        return_amt   = params[:ia_amount].to_i
        current_bal  = staff_current_balance(staff_id)

        # If editing existing record, adjust balance
        if params[:mid].to_i > 0
            old_entry = TrnIssueAmount.find_by(id: params[:mid], ia_compcode: @compcodes)
            if old_entry && old_entry.ia_type == 'R'
            current_bal += old_entry.ia_amount.to_i
            end
        end

        if return_amt > current_bal
            flash[:error] = "Return amount cannot exceed current balance (#{current_bal})"
            isFlags = false
        end
        end

        currentgrp =  params[:cur_ia_code].to_s.strip
        newgroup   =  params[:ia_code].to_s.strip
    
        if params[:mid].to_i>0

            if currentgrp.to_s.downcase != newgroup.to_s.downcase
                chkgrpobj   = TrnIssueAmount.where("ia_compcode=? AND LOWER(ia_code)=? ",@compcodes,newgroup.to_s.downcase)
                if chkgrpobj.length>0
                    flash[:error] = "Could not create duplicate ."
                    isFlags        = false
                end
            end
    
          if isFlags
                chkgrpobj   = TrnIssueAmount.where("ia_compcode=? AND id=?",@compcodes,mid).first
                if chkgrpobj
                    chkgrpobj.update(issue_amount_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                    modulename = "Issue Amount"
                    description = "Issue Amount Save: #{params[:ia_code]}"
                    process_request_log_data("SAVE", modulename, description)
               
                end
          end
        else
            chkgrpobj   = TrnIssueAmount.where("ia_compcode=? AND LOWER(ia_code)=?",@compcodes,newgroup.to_s.downcase)
            if chkgrpobj.length>0
              flash[:error] = "Could not be create duplicate."
             isFlags        = false
            end
              if isFlags
                  savegrp = TrnIssueAmount.new(issue_amount_params)
                  if savegrp.save
                      flash[:error] = "Data saved successfully"
                      isFlags       = true
                      modulename = "Issue Amount"
                      description = "Issue Amount Update: #{params[:ia_code]}"
                      process_request_log_data("UPDATE", modulename, description)
                  end
              end
    
        end
        if !isFlags
            session[:isErrorhandled] = 1
            # session[:postedpamams]   = params
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
            redirect_to  "#{root_url}issue_amount"
        else
            if params[:mid].to_i>0 
                redirect_to  "#{root_url}issue_amount/add_issue_amount/"+params[:mid].to_s
            else
                redirect_to  "#{root_url}issue_amount/add_issue_amount"
            end
              
        end
    
    end

    def destroy
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i >0
            @ListSate =  TrnIssueAmount.where("ia_compcode=? AND id=?", @compcodes,params[:id].to_i).first
               if @ListSate
                     @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
       end
       redirect_to "#{root_url}issue_amount"
    end

    private
    def get_issue_amount_list
        @compcodes      = session[:loggedUserCompCode] 
        
        if params[:page].to_i >0
            pages = params[:page]
            else
            pages = 1
            end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
            #  session[:req_faculty_list] = nil
          # end
          filter_search = params[:issue_amount] !=nil && params[:issue_amount] != '' ? params[:issue_amount].to_s.strip : session[:req_issue_amount].to_s.strip       
          iswhere       = "ia_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( ia_code LIKE '%#{filter_search}%' )"
            @issue_amount_search       = filter_search
            session[:req_issue_amount] = filter_search
          end    
          
        stdob =  TrnIssueAmount.where(iswhere)
        return stdob
    end

    private
    def issue_amount_params
        @compcodes  = session[:loggedUserCompCode]
        params[:ia_compcode] = @compcodes 
        params.permit(:ia_compcode,:ia_code,:ia_staff_id,:ia_date,:ia_amount,:ia_type,:ia_remarks)

    end

end
