class MemberSubscriptionsController < ApplicationController
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
        @member_subscriptions = get_member_subscriptions()
        printPath     =  "member_subscriptions/1_prt_member_subscriptions.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'member'
              
              @membersubscriptionsdetail   = print_member_subscriptions()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = StockinventoryPdf.new(@membersubscriptionsdetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_member_subscriptions.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def add_member_subscriptions
        @compcodes      = session[:loggedUserCompCode]
        @Lastcode=generate_regularization_series
        @MemberList = MstMembersList.where(["mmbr_compcode =?",@compcodes])         
        @MemberPlanList = MstMembershipPlan.where(["plan_compcode =?",@compcodes])         
        @subscription = nil
        if params[:id].to_i>0
            @subscription = TrnMemberSubscription.where("ms_compcode=? AND id=?",@compcodes,params[:id]).first
         end
    end

    def ajax_process
      @compCodes       = session[:loggedUserCompCode]
        if  params[:identity] != nil && params[:identity] != '' && params[:identity] ==  'SAVESUBSCR'
        create();
        return 
      end
    end

    def referesh_member_subscription
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        session[:req_member_subscription] = nil
        isFlags = true
        redirect_to "#{root_url}member_subscriptions"
    end

    def create
      @compcodes      = session[:loggedUserCompCode] 
      isFlags     = true
      mid         = params[:mid]
         message      = ""
        dtfiles      = []
        profileid    = ""
        profileimage = ""
        signimages   = ""
        mdid         = ""
        gdid         = ""
        mdfiles      = ""
      # begin
          if params[:ms_sbscrptn_no].to_s.blank?
             message =  "Subscription No. is Required"
             isFlags = false
          elsif
             params[:ms_member_id].to_s.blank?
             message =  "Member is Required"
             isFlags = false
          elsif
            params[:ms_plan_id].to_s.blank?
            message =  "Plan is Required"
            isFlags = false
          elsif
             params[:ms_start_date].to_s.blank?
             message =  "Start Date is Required"
             isFlags = false
            elsif
              params[:ms_amount_paid].to_s.blank?
              message =  "Amount Paid is Required"
              isFlags = false
            elsif
              params[:ms_payment_mode].to_s.blank?
              message =  "Payment Mode is Required"
              isFlags = false
          end

            currentgrp =  params[:cur_ms_sbscrptn_no].to_s.strip
            newgroup   =  params[:ms_sbscrptn_no].to_s.strip

              if params[:mid].to_i>0
                 if currentgrp.to_s.downcase != newgroup.to_s.downcase
                     chkgrpobj   = TrnMemberSubscription.where("ms_compcode=? AND LOWER(ms_sbscrptn_no)=? ",@compcodes,newgroup.to_s.downcase)
                     if chkgrpobj.length>0
                         message = "Subscription No. already exist!"
                         isFlags        = false
                     end
                 end
         
               if isFlags
                     chkgrpobj   = TrnMemberSubscription.where("ms_compcode=? AND id=?",@compcodes,mid).first
                     if chkgrpobj
                      profileid    = chkgrpobj.id
                         chkgrpobj.update(member_subscription_params)
                        message = "Data updated successfully"
                         isFlags       = true
                         modulename = "Member Subscription"
                         description = "Member Subscription Update: #{params[:ms_sbscrptn_no]}"
                         process_request_log_data("UPDATE", modulename, description)
                     end
               end
             else
                 chkgrpobj   = TrnMemberSubscription.where("ms_compcode=? AND LOWER(ms_sbscrptn_no)=?",@compcodes,newgroup.to_s.downcase)
                 if chkgrpobj.length>0
                  message = "Subscription No. already exist!"
                  isFlags        = false
                 end
                   if isFlags
                       savegrp = TrnMemberSubscription.new(member_subscription_params)
                       if savegrp.save
                           profileid    = savegrp.id.to_i
                          chkgrpobjx   = TrnMemberSubscription.where("ms_compcode=? AND id=?",@compcodes,profileid).first
                           message = "Data saved successfully"
                           isFlags       = true
                           modulename = "Member Subscription"
                           description = "Member Subscription Save: #{params[:ms_sbscrptn_no]}"
                           process_request_log_data("SAVE", modulename, description)
                      
                       end
                   end
         
             end
             if !isFlags
                 session[:isErrorhandled] = 1
                 session[:postedpamams]   = nil
                #  session[:sess_fclty_img] = params[:fclty_img]
                 session[:sess_ms_sbscrptn_no] = params[:ms_sbscrptn_no]
                 session[:sess_ms_member_id] = params[:ms_member_id]
                 session[:sess_ms_plan_id] = params[:ms_plan_id]
                 session[:sess_ms_start_date] = params[:ms_start_date]
                 session[:sess_ms_end_date] = params[:ms_end_date]
                 session[:sess_ms_amount_paid] = params[:ms_amount_paid]
                 session[:sess_ms_payment_mode] = params[:ms_payment_mode]
                 session[:sess_ms_status] = params[:ms_status]
                 session[:sess_ms_remarks] = params[:ms_remarks]

             else
                 session[:isErrorhandled] = nil
                 session[:postedpamams]   = nil
                #  session[:sess_fclty_img] = nil
                 session[:sess_ms_sbscrptn_no] = nil
                 session[:sess_ms_member_id] = nil
                 session[:sess_ms_plan_id] = nil
                 session[:sess_ms_start_date] = nil
                 session[:sess_ms_end_date] = nil
                 session[:sess_ms_amount_paid] = nil
                 session[:sess_ms_payment_mode] = nil
                 session[:sess_ms_status] = nil
                 session[:sess_ms_remarks] = nil

                 isFlags = true
             end
            #  rescue Exception => exc
            #      flash[:error] =  "ERROR: #{exc.message}"
            #      session[:isErrorhandled] = 1
            #      isFlags = false
            #  end

            # chkgrpobj   = MstFaculty.where("fclty_compcode=? ",@compcodes)
            # respond_to do |format|
            #   format.json { render :json => { 'data'=>chkgrpobj,:status=>isFlags,:message=>message} }
            # end

          respond_to do |format|
            format.json { render :json => {  "message"=>message,:profileid=>profileid,:status=>isFlags} }
          end
    end

    def destroy
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i >0
            @ListSate =  TrnMemberSubscription.where("ms_compcode=? AND id=?", @compcodes,params[:id].to_i).first
               if @ListSate
                     @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
       end
       redirect_to "#{root_url}member_subscriptions"
    end

    def get_latest_subscription(member_id)
        TrnMemberSubscription.where("ms_compcode=? AND ms_member_id=?", session[:loggedUserCompCode], member_id)
            .order("ms_end_date DESC").first
    end

    def check_active_subscription(member_id)
        curr = get_latest_subscription(member_id)
        return false if curr.nil?
        return curr.ms_end_date >= Date.today
    end

    def calculate_end_date(start_date, plan_id)
        plan = MstMembershipPlan.where("plan_compcode=? AND id=?", session[:loggedUserCompCode], plan_id).first
        return start_date if plan.nil?
        return start_date + plan.plan_duration_days.to_i.days
    end

    def subscription_status(end_date)
        end_date < Date.today ? "EXPIRED" : "ACTIVE"
    end

    private
    def get_member_subscriptions
        @compcodes      = session[:loggedUserCompCode] 
        
        if params[:page].to_i >0
            pages = params[:page]
            else
            pages = 1
            end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
            #  session[:req_faculty_list] = nil
          # end
          filter_search = params[:member_subscriptions] !=nil && params[:member_subscriptions] != '' ? params[:member_subscriptions].to_s.strip : session[:req_member_subscriptions].to_s.strip       
          iswhere       = "ms_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( ms_sbscrptn_no LIKE '%#{filter_search}%' )"
            @member_list_search       = filter_search
            session[:req_member_subscriptions] = filter_search
          end    
          
        stdob =  TrnMemberSubscription.where(iswhere).order("ms_sbscrptn_no ASC")
        return stdob
    end

    private
    def members_params
        params[:ms_compcode]     = session[:loggedUserCompCode] 
        params.permit(:ms_compcode,:ms_sbscrptn_no,:ms_plan_id,:ms_start_date,:ms_end_date,:ms_amount_paid,:ms_payment_mode,:ms_status,:ms_remarks)

    end

    private
    def generate_regularization_series
        @compcodes      = session[:loggedUserCompCode]
         @isCode     = 0
         @Startx     = '0000' 
         @recCodes  = TrnMemberSubscription.where(["ms_compcode = ? AND ms_sbscrptn_no <>'' ", @compcodes]).order('ms_sbscrptn_no DESC').first
         if @recCodes
           @isCode    = @recCodes.ms_sbscrptn_no.to_i
         end	  
           @sumXOfCode    = @isCode.to_i + 1
           if @sumXOfCode.to_s.length < 2
             @sumXOfCode = p @Startx.to_s + @sumXOfCode.to_s
           elsif @sumXOfCode.to_s.length < 3
             @sumXOfCode = p "000" + @sumXOfCode.to_s
           elsif @sumXOfCode.to_s.length < 4
             @sumXOfCode = p "00" + @sumXOfCode.to_s
           elsif @sumXOfCode.to_s.length < 5
             @sumXOfCode = p "0" + @sumXOfCode.to_s
           elsif @sumXOfCode.to_s.length >=5
             @sumXOfCode =  @sumXOfCode.to_i
           end
         return @sumXOfCode
    end
end
