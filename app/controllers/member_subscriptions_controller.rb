include GlobalCodeGenerator

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
        @MemberPlanList = MstMembershipPlan.where(plan_compcode: @compcodes)  
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
      @compcodes = session[:loggedUserCompCode]
      @Lastcode = generate_code(table: TrnMemberSubscription, column: "ms_sbscrptn_no", prefix: "SUB", compcode: session[:loggedUserCompCode])
      @MemberList = MstMembersList.where(mmbr_compcode: @compcodes)
      @MemberPlanList = MstMembershipPlan.where(plan_compcode: @compcodes)
      @subscription = nil

      if params[:renew].to_s == '1'
        params[:id] = nil
        @subscription = nil
        member_id = params[:member_id].to_i

        session[:sess_ms_member_id]  = member_id
        session[:sess_ms_start_date] = nil
        session[:sess_ms_plan_id]    = nil

        @latest = get_latest_subscription(member_id)

        if @latest
          session[:sess_ms_plan_id]    = @latest.ms_plan_id
          session[:sess_ms_start_date] = (@latest.ms_end_date + 1.day).strftime("%d-%b-%Y")
          plan = MstMembershipPlan.find_by(id: @latest.ms_plan_id)
          if plan&.plan_is_open.to_i == 1
            session[:sess_ms_open_amount]   = nil
            session[:sess_ms_open_end_date] = nil
          end
        else
          session[:sess_ms_start_date] = Date.today.strftime("%d-%b-%Y")
        end

      else
        # Clear all renew session values on fresh entry
        session[:sess_ms_member_id]    = nil
        session[:sess_ms_plan_id]      = nil
        session[:sess_ms_start_date]   = nil
        session[:sess_ms_open_amount]  = nil
        session[:sess_ms_open_end_date] = nil
      end

      if params[:id].to_i > 0
        @subscription = TrnMemberSubscription.where("ms_compcode=? AND id=?", @compcodes, params[:id]).first
      end
    end

    def ajax_process
      @compCodes       = session[:loggedUserCompCode]
      if params[:identity] != nil && params[:identity] != '' && params[:identity] ==  'SAVESUBSCR'
        create();
        return 
      elsif params[:identity] != nil && params[:identity] != '' && params[:identity] ==  'FILLENDDATE'
        fill_end_date();
        return
      elsif params[:identity] != nil && params[:identity] != '' && params[:identity] ==  'COLLECTPAY'
        collect_payment();
        return
      elsif params[:identity] != nil && params[:identity] != '' && params[:identity] ==  'EXTENDSUB'
        extend_subscription();
        return
      end
    end

    # Records an additional payment against an existing subscription (partial
    # dues, split cash+UPI, pay-later). Appends to the trn_payments ledger and
    # re-syncs the subscription's denormalized ms_amount_paid so every screen
    # (Member List uses that field; Profile/Dashboard use the ledger) agrees.
    def collect_payment
      @compcodes = session[:loggedUserCompCode]
      message    = ""
      isFlags    = true

      subscription = TrnMemberSubscription.where(
        "ms_compcode = ? AND id = ?", @compcodes, params[:subscription_id]
      ).first

      if subscription.nil?
        message = "Subscription not found."
        isFlags = false
      elsif params[:pay_amount].to_f <= 0
        message = "Enter a valid payment amount."
        isFlags = false
      elsif params[:pay_mode].to_s.blank?
        message = "Select a payment mode."
        isFlags = false
      end

      if isFlags
        TrnPayment.create(
          pay_compcode: @compcodes,
          pay_no: generate_code(table: TrnPayment, column: "pay_no", prefix: "PAY", compcode: @compcodes),
          pay_ref_type: 'MEMBER_SUBSCRIPTION',
          pay_ref_id: subscription.id,
          pay_date: params[:pay_date].presence || Date.today.strftime("%d-%b-%Y"),
          pay_amount: params[:pay_amount],
          pay_mode: params[:pay_mode],
          pay_remarks: params[:pay_remarks].presence || 'Dues payment'
        )

        # Keep the denormalized field in sync with the ledger total.
        total_paid = TrnPayment.where(
          pay_ref_type: 'MEMBER_SUBSCRIPTION', pay_ref_id: subscription.id
        ).sum(:pay_amount)
        subscription.update(ms_amount_paid: total_paid)

        message = "Payment recorded successfully"
        process_request_log_data("SAVE", "Member Subscription",
          "Collected payment #{params[:pay_amount]} for subscription #{subscription.ms_sbscrptn_no}")
      end

      respond_to do |format|
        format.json { render json: { status: isFlags, message: message } }
      end
    end

    # Pushes a subscription's end date forward by N days (membership freeze /
    # hold for travel or injury, or a goodwill extension). Date-axis only —
    # it does NOT touch the payment ledger. Recomputes status and appends a
    # short audit note to the subscription's remarks.
    def extend_subscription
      @compcodes = session[:loggedUserCompCode]
      message    = ""
      isFlags    = true
      days       = params[:extend_days].to_i

      subscription = TrnMemberSubscription.where(
        "ms_compcode = ? AND id = ?", @compcodes, params[:subscription_id]
      ).first

      if subscription.nil?
        message = "Subscription not found."
        isFlags = false
      elsif days <= 0
        message = "Enter a valid number of days."
        isFlags = false
      end

      if isFlags
        new_end = subscription.ms_end_date + days.days
        reason  = params[:extend_reason].to_s.strip
        note    = "[+#{days}d on #{Date.today.strftime('%d-%b-%Y')}#{reason.present? ? ": #{reason}" : ''}]"

        subscription.update(
          ms_end_date: new_end,
          ms_status:   subscription_status(new_end),
          ms_remarks:  [subscription.ms_remarks.to_s.strip, note].reject(&:blank?).join(' ')
        )

        message = "Membership extended by #{days} day(s). New end date: #{new_end.strftime('%d-%b-%Y')}."
        process_request_log_data("UPDATE", "Member Subscription",
          "Extended subscription #{subscription.ms_sbscrptn_no} by #{days} days (#{reason})")
      end

      respond_to do |format|
        format.json { render json: { status: isFlags, message: message } }
      end
    end

    def referesh_member_subscription
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        session[:req_member_search]  = nil
        session[:req_status_filter]        = nil
        session[:req_plan_filter]          = nil
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
            # elsif
            #   params[:ms_payment_mode].to_s.blank?
            #   message =  "Payment Mode is Required"
            #   isFlags = false
          end

          plan = MstMembershipPlan.find_by(
            plan_compcode: @compcodes,
            id: params[:ms_plan_id]
          )

          if plan.nil?
            message = "Invalid membership plan"
            isFlags = false
          end

     if isFlags

        is_open_plan = plan.plan_is_open.to_i == 1
        params[:ms_skip_due_check] = is_open_plan ? 1 : 0

        if is_open_plan
          open_amount = params[:ms_open_amount].to_f

          params[:ms_plan_amount]     = open_amount
          params[:ms_final_amount]    = open_amount
          params[:ms_discount_amount] = 0

          open_end = Date.parse(params[:ms_open_end_date])

          params[:ms_open_duration_days] =
            (open_end - Date.parse(params[:ms_start_date])).to_i

          params[:ms_end_date] = open_end

        else
          params[:ms_plan_amount]     = plan.plan_mrp_amount
          params[:ms_final_amount]    = plan.plan_final_amount
          params[:ms_discount_amount] =
            plan.plan_mrp_amount.to_f - plan.plan_final_amount.to_f
        end

            member_id = params[:ms_member_id].to_i

            currentgrp =  params[:cur_ms_sbscrptn_no].to_s.strip
            newgroup   =  params[:ms_sbscrptn_no].to_s.strip

            latest = get_latest_subscription(member_id)

            if mid.to_i == 0  
              if latest.present?
                if latest.ms_end_date >= Date.parse(params[:ms_start_date])
                  message = "Member already has an ACTIVE subscription until #{latest.ms_end_date.strftime('%d-%b-%Y')}. Please choose a start date after expiry."
                  isFlags = false
                end
              end
            end

              start_date = Date.parse(params[:ms_start_date])

              if is_open_plan
                end_date = open_end   # already parsed
              else
                end_date = calculate_end_date(start_date, params[:ms_plan_id])
              end

              params[:ms_end_date] = end_date
              params[:ms_status]   = subscription_status(end_date)

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
                       TrnPayment.create(
                          pay_compcode: @compcodes,
                          pay_no: generate_code(table: TrnPayment,column: "pay_no",prefix: "PAY",compcode: session[:loggedUserCompCode]),
                          pay_ref_type: 'MEMBER_SUBSCRIPTION',
                          pay_ref_id: savegrp.id,
                          pay_date: params[:ms_start_date],
                          pay_amount: params[:ms_amount_paid],
                          pay_mode: params[:ms_payment_mode],
                          pay_remarks: 'Subscription payment'
                        )
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
            end
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
      plan = MstMembershipPlan.find_by(
        plan_compcode: session[:loggedUserCompCode],
        id: plan_id
      )

      return start_date if plan.nil?

      # OPEN PLAN
      if plan.plan_is_open.to_i == 1
        return Date.parse(params[:ms_open_end_date])
      end

      months = plan.plan_duration_months.to_i
      start_date.advance(months: months) - 1.day
    end


    def subscription_status(end_date)
        end_date < Date.today ? "EXPIRED" : "ACTIVE"
    end

    def get_member_subscriptions
      @compcodes = session[:loggedUserCompCode]
      is_search  = params[:server_request].to_s == 'Y'

      if is_search
        filter_search  = params[:member_search].to_s.strip
        @status_filter = params[:status_filter].to_s.strip
        @plan_filter   = params[:plan_filter].to_s.strip
        session[:req_member_search]  = filter_search
        session[:req_status_filter]  = @status_filter
        session[:req_plan_filter]    = @plan_filter
      else
        filter_search  = session[:req_member_search].to_s.strip
        @status_filter = session[:req_status_filter].to_s.strip
        @plan_filter   = session[:req_plan_filter].to_s.strip
      end

      @status_filter = 'A' unless @status_filter.present?
      @plan_filter   = '1' unless @plan_filter.present?
      @member_search = filter_search

      iswhere = "ms_compcode ='#{@compcodes}'"

      if filter_search.present?
        # Search subscription no directly
        sub_match = "ms_sbscrptn_no LIKE '%#{filter_search}%'"

        # Search member name and contact
        matching_ids = MstMembersList
                        .where("mmbr_compcode = ? AND (mmbr_name LIKE ? OR mmbr_contact LIKE ?)",
                                @compcodes, "%#{filter_search}%", "%#{filter_search}%")
                        .pluck(:id)

        if matching_ids.present?
          iswhere += " AND (#{sub_match} OR ms_member_id IN (#{matching_ids.join(',')}))"
        else
          iswhere += " AND (#{sub_match})"
        end
      end

      if @status_filter == 'E'
        iswhere += " AND ms_end_date < '#{Date.today}'"
      else
        iswhere += " AND ms_end_date >= '#{Date.today}'"
      end

      if @plan_filter.present?
        iswhere += " AND ms_plan_id = '#{@plan_filter}'"
      end

      stdob = TrnMemberSubscription.where(iswhere).order("ms_end_date ASC")

      member_ids = stdob.map(&:ms_member_id).uniq
      plan_ids   = stdob.map(&:ms_plan_id).uniq

      @members_hash = MstMembersList
                        .where("mmbr_compcode=? AND id IN (?)", @compcodes, member_ids)
                        .index_by(&:id)
      @plans_hash   = MstMembershipPlan
                        .where("plan_compcode=? AND id IN (?)", @compcodes, plan_ids)
                        .index_by(&:id)

      return stdob
    end

    private
    def member_subscription_params
        params[:ms_compcode]     = session[:loggedUserCompCode] 
        params.permit(:ms_compcode,:ms_sbscrptn_no,:ms_member_id,:ms_plan_id,:ms_plan_amount,:ms_final_amount,:ms_discount_amount,:ms_start_date,:ms_end_date,:ms_amount_paid,:ms_payment_mode,:ms_status,:ms_remarks,:ms_open_amount,:ms_open_end_date,:ms_open_duration_days,:ms_skip_due_check)
    end

    def fill_end_date
      plan = MstMembershipPlan.find_by(id: params[:ms_plan_id])

      if plan.present?

        # OPEN PLAN
        if plan.plan_is_open.to_i == 1
          render json: {
            status: true,
            is_open: true
          }
          return
        end

        if params[:ms_start_date].present?
          start_date = Date.strptime(params[:ms_start_date], "%d-%b-%Y")
          months     = plan.plan_duration_months.to_i

          end_date = start_date.advance(months: months) - 1.day

          render json: {
            status: true,
            is_open: false,
            end_date: end_date.strftime("%d-%b-%Y")
          }
        else
          render json: { status: false }
        end

      else
        render json: { status: false }
      end
    end

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
