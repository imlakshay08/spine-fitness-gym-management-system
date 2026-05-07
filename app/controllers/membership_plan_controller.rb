class MembershipPlanController < ApplicationController
    before_action      :require_login
    before_action      :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]

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
        @membership_plan = get_membership_plan()
        @StockList = MstStockList.where(["sl_compcode =?",@compcodes]) 
        printPath     =  "membership_plan/1_prt_membership_plan.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'membership'
              
              @membershipplandetail   = print_membership_plan()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = StockinventoryPdf.new(@membershipplandetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_membership_plan.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def add_membership_plan
        @compcodes      = session[:loggedUserCompCode]
        @memberplan = nil
        if params[:id].to_i>0
            @memberplan = MstMembershipPlan.where("plan_compcode=? AND id=?",@compcodes,params[:id]).first
         end
    end

    def referesh_membership_plan
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        isFlags = true
        redirect_to  "#{root_url}membership_plan"
    end

    def create
        @compcodes      = session[:loggedUserCompCode] 
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:plan_name].to_s.blank?
           flash[:error] =  "Plan Name is Required"
           isFlags = false
        end
        if params[:plan_duration_months].to_s.blank?
          flash[:error] =  "Duration Months is Required"
          isFlags = false
        end
        if params[:plan_amount].to_s.blank?
            flash[:error] =  "Amount is Required"
            isFlags = false
        end
        if params[:plan_description].to_s.blank?
            flash[:error] =  "Description is Required"
            isFlags = false
        end

        currentgrp =  params[:cur_plan_name].to_s.strip
        newgroup   =  params[:plan_name].to_s.strip
    
        if params[:mid].to_i>0

            if currentgrp.to_s.downcase != newgroup.to_s.downcase
                chkgrpobj   = MstMembershipPlan.where("plan_compcode=? AND LOWER(plan_name)=? ",@compcodes,newgroup.to_s.downcase)
                if chkgrpobj.length>0
                    flash[:error] = "Could not create duplicate ."
                    isFlags        = false
                end
            end
    
          if isFlags
                chkgrpobj   = MstMembershipPlan.where("plan_compcode=? AND id=?",@compcodes,mid).first
                if chkgrpobj
                    chkgrpobj.update(membership_plan_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                    modulename = "Membership Plan"
                    description = "Membership Plan Save: #{params[:plan_name]}"
                    process_request_log_data("SAVE", modulename, description)
               
                end
          end
        else
            chkgrpobj   = MstMembershipPlan.where("plan_compcode=? AND LOWER(plan_name)=?",@compcodes,newgroup.to_s.downcase)
            if chkgrpobj.length>0
              flash[:error] = "Could not be create duplicate."
             isFlags        = false
            end
              if isFlags
                  savegrp = MstMembershipPlan.new(membership_plan_params)
                  if savegrp.save
                      flash[:error] = "Data saved successfully"
                      isFlags       = true
                      modulename = "Membership Plan"
                      description = "Membership Plan Update: #{params[:plan_name]}"
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
            redirect_to  "#{root_url}membership_plan"
        else
            if params[:mid].to_i>0 
                redirect_to  "#{root_url}membership_plan/add_membership_plan/"+params[:mid].to_s
            else
                redirect_to  "#{root_url}membership_plan/add_membership_plan"
            end
              
        end
    
    end

    def destroy
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i >0
            @ListSate =  MstMembershipPlan.where("plan_compcode=? AND id=?", @compcodes,params[:id].to_i).first
               if @ListSate
                     @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
       end
       redirect_to "#{root_url}membership_plan"
    end

    private
    def get_membership_plan
        @compcodes      = session[:loggedUserCompCode] 
        if params[:page].to_i >0
            pages = params[:page]
        else
            pages = 1
        end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
        session[:req_membership_plan] = nil
          # end
        filter_search = params[:membership_plan] !=nil && params[:membership_plan] != '' ? params[:membership_plan].to_s.strip : session[:req_membership_plan].to_s.strip       

          iswhere       = "plan_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( plan_name LIKE '%#{filter_search}%')"
            @membership_plan_search       = filter_search
            session[:req_membership_plan] = filter_search
          end     
        
          stdob =  MstMembershipPlan.where(iswhere).order("plan_name ASC")
          return stdob

    end

    private
    def membership_plan_params
        @compcodes      = session[:loggedUserCompCode] 
        params[:plan_compcode]	    = @compcodes
        params.permit(:plan_compcode,:plan_name,:plan_amount,:plan_description,:plan_duration_months,:plan_mrp_amount,:plan_final_amount)

    end
end
