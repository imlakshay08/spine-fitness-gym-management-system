include GlobalCodeGenerator

class MemberListController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:format_oblig_date,:get_dob_calculate
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @member_list = get_member_list()
        @member     = nil
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        printPath     =  "member_list/1_prt_member_list.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'member'
              
              @memberdetail   = print_member_list()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = FacultyPdf.new(@memberdetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_member_list.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def ajax_process
      @compCodes       = session[:loggedUserCompCode]
      if  params[:identity] != nil && params[:identity] != '' && params[:identity] ==  'BIRTHCALC'
        get_birth_date_calculation();
        return 
      elsif  params[:identity] != nil && params[:identity] != '' && params[:identity] ==  'SAVEFACLTY'
        create();
        return 
      end
    end

    def add_member
        @compcodes      = session[:loggedUserCompCode] 
        @Lastcode=generate_code(table: MstMembersList, column: "mmbr_code", prefix: "M", compcode: session[:loggedUserCompCode])
        @member     = nil
        if params[:id].to_i>0
            @member = MstMembersList.where("mmbr_compcode=? AND id=?",@compcodes,params[:id]).first
            
        end
    end

  def referesh_member_list
    session[:isErrorhandled]           = nil
    session[:postedpamams]             = nil
    session[:req_member_list]          = nil
    session[:req_member_status_filter] = nil
    session[:req_member_plan_filter]   = nil  # ADD THIS
    redirect_to "#{root_url}member_list"
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
          if params[:mmbr_code].to_s.blank?
             message =  "Member Code is Required"
             isFlags = false
          elsif
             params[:mmbr_name].to_s.blank?
             message =  "Name is Required"
             isFlags = false
          elsif
            params[:mmbr_gender].to_s.blank?
            message =  "Gender is Required"
            isFlags = false
          # elsif
          #    params[:mmbr_dob].to_s.blank?
          #    message =  "Date of Birth is Required"
          #    isFlags = false
            elsif
              params[:mmbr_contact].to_s.blank?
              message =  "Contact No. is Required"
              isFlags = false
          end

            currentgrp =  params[:cur_mmbr_code].to_s.strip
            newgroup   =  params[:mmbr_code].to_s.strip
            mobileno   =  params[:mmbr_contact].to_s.strip
            if mobileno.length<10
                message = "Mobile number should be 10 digits!"
                isFlags = false
            end 

              if params[:mid].to_i>0
                 if currentgrp.to_s.downcase != newgroup.to_s.downcase
                     chkgrpobj   = MstMembersList.where("mmbr_compcode=? AND LOWER(mmbr_code)=? ",@compcodes,newgroup.to_s.downcase)
                     if chkgrpobj.length>0
                         message = "Member Code already exist!"
                         isFlags        = false
                     end
                 end
         
               if isFlags
                     chkgrpobj   = MstMembersList.where("mmbr_compcode=? AND id=?",@compcodes,mid).first
                     if chkgrpobj
                      profileid    = chkgrpobj.id
                         chkgrpobj.update(members_params)
                        message = "Data updated successfully"
                         isFlags       = true
                         modulename = "Member List"
                         description = "Member List Update: #{params[:mmbr_code]}"
                         process_request_log_data("UPDATE", modulename, description)
                     end
               end
             else
                 chkgrpobj   = MstMembersList.where("mmbr_compcode=? AND LOWER(mmbr_code)=?",@compcodes,newgroup.to_s.downcase)
                 if chkgrpobj.length>0
                  message = "Member Code already exist!"
                  isFlags        = false
                 end
                   if isFlags
                       savegrp = MstMembersList.new(members_params)
                       if savegrp.save
                           profileid    = savegrp.id.to_i
                          chkgrpobjx   = MstMembersList.where("mmbr_compcode=? AND id=?",@compcodes,profileid).first
                           message = "Data saved successfully"
                           isFlags       = true
                           modulename = "Member List"
                           description = "Member List Save: #{params[:mmbr_code]}"
                           process_request_log_data("SAVE", modulename, description)
                      
                       end
                   end
         
             end
             if !isFlags
                 session[:isErrorhandled] = 1
                 session[:postedpamams]   = nil
                #  session[:sess_fclty_img] = params[:fclty_img]
                 session[:sess_mmbr_code] = params[:mmbr_code]
                 session[:sess_mmbr_name] = params[:mmbr_name]
                 session[:sess_mmbr_gender] = params[:mmbr_gender]
                 session[:sess_mmbr_dob] = params[:mmbr_dob]
                 session[:sess_mmbr_join_date] = params[:mmbr_join_date]
                 session[:sess_mmbr_leave_date] = params[:mmbr_leave_date]
                 session[:sess_mmbr_mrtl_stats] = params[:mmbr_mrtl_stats]
                 session[:sess_mmbr_aadhaar] = params[:mmbr_aadhaar]
                 session[:sess_mmbr_pan] = params[:mmbr_pan]
                 session[:sess_mmbr_contact] = params[:mmbr_contact]
                 session[:sess_mmbr_addr1] = params[:mmbr_addr1]
                 session[:sess_mmbr_addr2] = params[:mmbr_addr2]
                 session[:sess_mmbr_city] = params[:mmbr_city]
                 session[:sess_mmbr_email] = params[:mmbr_email]
                 session[:sess_mmbr_father] = params[:mmbr_father]
                 session[:sess_mmbr_mother] = params[:mmbr_mother]

             else
                 session[:isErrorhandled] = nil
                 session[:postedpamams]   = nil
                #  session[:sess_fclty_img] = nil
                 session[:sess_mmbr_code] = nil
                 session[:sess_mmbr_name] = nil
                 session[:sess_mmbr_gender] = nil
                 session[:sess_mmbr_dob] = nil
                 session[:sess_mmbr_join_date] = nil
                 session[:sess_mmbr_leave_date] = nil
                 session[:sess_mmbr_mrtl_stats] = nil
                 session[:sess_mmbr_aadhaar] = nil
                 session[:sess_mmbr_pan] = nil
                 session[:sess_mmbr_contact] = nil
                 session[:sess_mmbr_addr1] =nil
                 session[:sess_mmbr_addr2] = nil
                 session[:sess_mmbr_city] = nil
                 session[:sess_mmbr_email] = nil
                 session[:sess_mmbr_father] =nil
                 session[:sess_mmbr_mother] = nil

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
            @ListSate =  MstMembersList.where("mmbr_compcode=? AND id=?", @compcodes,params[:id].to_i).first
               if @ListSate
                     @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
       end
       redirect_to "#{root_url}member_list"
    end

      def save_manual_mapping
    compcode = session[:loggedUserCompCode]
    member_id = params[:member_id].to_s
    device_user_id = params[:device_user_id].to_s.strip

    # Check if mapping already exists
    existing = TrnMemberBiometricMapping.find_by(
      mbm_compcode: compcode,
      mbm_member_id: member_id
    )

    if existing
      existing.update(
        mbm_device_user_id: device_user_id,
        mbm_is_active: 'Y'
      )
    else
      TrnMemberBiometricMapping.create!(
        mbm_compcode:       compcode,
        mbm_member_id:      member_id,
        mbm_device_user_id: device_user_id,
        mbm_device_sn:      'NFZ8253402448',
        mbm_is_active:      'Y'
      )
    end

    render json: { status: true, message: "Mapping saved" }
  rescue => e
    render json: { status: false, message: e.message }
  end

  def remove_mapping
    mapping = TrnMemberBiometricMapping.find_by(id: params[:mapping_id])
    if mapping
      mapping.update(mbm_is_active: 'N')
      render json: { status: true }
    else
      render json: { status: false, message: "Not found" }
    end
  end

   def profile
    @compcodes = session[:loggedUserCompCode]
    
    # Load the member
    @member = MstMembersList.where(
      "mmbr_compcode = ? AND id = ?", @compcodes, params[:id]
    ).first
    
    # If member not found, go back to list
    if @member.nil?
      redirect_to "#{root_url}member_list"
      return
    end

    # Load ALL subscriptions for this member, newest first
    @subscriptions = TrnMemberSubscription.where(
      "ms_compcode = ? AND ms_member_id = ?", @compcodes, @member.id
    ).order("ms_end_date DESC")

    # The latest subscription is the first one
    @latest_sub = @subscriptions.first

    # Load plan names for all subscriptions at once (no N+1 query)
    plan_ids = @subscriptions.map(&:ms_plan_id).uniq
    @plans_hash = MstMembershipPlan
      .where("plan_compcode = ? AND id IN (?)", @compcodes, plan_ids)
      .index_by(&:id)

    # Load all payments for this member's subscriptions at once
    sub_ids = @subscriptions.map(&:id)
    @payments_hash = TrnPayment
      .where(pay_ref_type: 'MEMBER_SUBSCRIPTION', pay_ref_id: sub_ids)
      .group(:pay_ref_id)
      .sum(:pay_amount).transform_keys(&:to_i)
    # @payments_hash is now: { subscription_id => total_amount_paid }

    # Load biometric mapping
    @biometric = TrnMemberBiometricMapping.find_by(
      mbm_compcode: @compcodes,
      mbm_member_id: @member.id.to_s,
      mbm_is_active: 'Y'
    )

    # Count attendance for this member (today and total)
    @attendance_today = TrnMemberAttendance.where(
      att_compcode: @compcodes,
      att_member_id: @member.id,
      att_punch_date: Date.today
    ).count

    @attendance_total = TrnMemberAttendance.where(
      att_compcode: @compcodes,
      att_member_id: @member.id
    ).count
  end

    private
 def get_member_list
  @compcodes = session[:loggedUserCompCode]

  # Read filters from params or session
  if params[:server_request].present?
    @member_status_filter = params[:status_filter].to_s.strip
    @member_plan_filter   = params[:plan_filter].to_s.strip
    session[:req_member_status_filter] = @member_status_filter
    session[:req_member_plan_filter]   = @member_plan_filter
  else
    @member_status_filter = session[:req_member_status_filter].to_s.strip
    @member_plan_filter   = session[:req_member_plan_filter].to_s.strip
  end

  # Load ALL members — 1 DB call
  stdob = MstMembersList
    .where("mmbr_compcode = ?", @compcodes)
    .order("mmbr_code ASC")

  member_ids = stdob.map(&:id)

  # Load ALL latest subscriptions for these members — 1 DB call
  subscriptions = TrnMemberSubscription
    .where("ms_compcode = ? AND ms_member_id IN (?)", @compcodes, member_ids)
    .order("ms_end_date DESC")

  @latest_subscription_hash = subscriptions
    .group_by { |s| s.ms_member_id.to_i }
    .transform_values(&:first)

  # Load plan names — 1 DB call
  plan_ids = subscriptions.map(&:ms_plan_id).uniq
  @plans_hash = MstMembershipPlan
    .where("plan_compcode = ? AND id IN (?)", @compcodes, plan_ids)
    .index_by(&:id)

  # Load MemberPlanList for dropdown — 1 DB call
  @MemberPlanList = MstMembershipPlan.where(plan_compcode: @compcodes)

  # Sort in Ruby — zero extra DB calls
  # Active (soonest expiry first) → Expired (most recent first) → No sub
  stdob = stdob.sort_by do |member|
    latest = @latest_subscription_hash[member.id]
    if latest.nil?
      [2, Date.today]
    elsif latest.ms_end_date >= Date.today
      [0, -latest.ms_end_date.to_time.to_i]
    else
      [1, -latest.ms_end_date.to_time.to_i]
    end
  end

  # Status filter in Ruby — zero extra DB calls
  stdob = case @member_status_filter
  when 'E'  # Expired
    stdob.select { |m| l = @latest_subscription_hash[m.id]; l && l.ms_end_date < Date.today }
  when 'N'  # No subscription
    stdob.select { |m| @latest_subscription_hash[m.id].nil? }
  else      # Active (default)
    stdob.select { |m| @latest_subscription_hash[m.id]&.ms_end_date&.>=(Date.today) }
  end

  # Plan filter in Ruby — zero extra DB calls
  if @member_plan_filter.present?
    stdob = stdob.select do |m|
      latest = @latest_subscription_hash[m.id]
      latest && latest.ms_plan_id.to_s == @member_plan_filter.to_s
    end
  end

  return stdob
end

    private
    def members_params
        params[:mmbr_compcode]     = session[:loggedUserCompCode] 
                params[:mmbr_entry_date] = Date.today
        params.permit(:mmbr_compcode,:mmbr_city,:mmbr_mother,:mmbr_father,:mmbr_contact,:mmbr_email,:mmbr_addr1,:mmbr_addr2,:mmbr_mrtl_stats,:mmbr_aadhaar,:mmbr_code,:mmbr_name,:mmbr_gender,:mmbr_dob,:mmbr_join_date,:mmbr_leave_date,:mmbr_entry_date)
                    # chkgrpobj   = MstFaculty.where("fclty_compcode=? ",@compcodes)

    end

    private
    def generate_regularization_series
        @compcodes      = session[:loggedUserCompCode]
         @isCode     = 0
         @Startx     = '0000' 
         @recCodes  = MstMembersList.where(["mmbr_compcode = ? AND mmbr_code <>'' ", @compcodes]).order('mmbr_code DESC').first
         if @recCodes
           @isCode    = @recCodes.mmbr_code.to_i
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
