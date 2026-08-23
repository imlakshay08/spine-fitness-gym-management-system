include GlobalCodeGenerator

class MemberListController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:format_oblig_date,:get_dob_calculate
    def index
        @compcodes      = session[:loggedUserCompCode] 
       # @member_list = get_member_list()
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

  def datatable
    compcode = session[:loggedUserCompCode]
    vc       = view_context

    draw    = params[:draw].to_i
    start   = params[:start].to_i
    length  = params[:length].to_i
    length  = 10 if length <= 0
    search  = params.dig(:search, :value).to_s.strip.downcase
    ord_idx = params.dig(:order, "0", :column).to_i
    ord_dir = (params.dig(:order, "0", :dir) == "desc") ? :desc : :asc

    # --- same data loading as the page (3 queries total) ---
    # The default list is people on the roll; "removed" opens the archive so a
    # member taken off the list by mistake can be put back.
    archived   = params[:view].to_s == 'removed'
    members    = (archived ? MstMembersList.removed : MstMembersList.on_roll)
                   .where("mmbr_compcode = ?", compcode)
                   .order("mmbr_name ASC").to_a
    member_ids = members.map(&:id)

    subs = TrnMemberSubscription
             .where("ms_compcode = ? AND ms_member_id IN (?)", compcode, member_ids)
             .order("ms_end_date DESC")
    latest_sub = subs.group_by { |s| s.ms_member_id.to_i }.transform_values(&:first)

    plan_ids = subs.map(&:ms_plan_id).uniq
    plans    = MstMembershipPlan.where("plan_compcode = ? AND id IN (?)", compcode, plan_ids)
                                .index_by(&:id)

    records_total = members.size

    # --- build a searchable struct per member ---
    rows = members.map do |m|
      latest    = latest_sub[m.id]
      plan      = latest ? plans[latest.ms_plan_id.to_i] : nil
      is_active = latest && latest.ms_end_date >= Date.today
      days_left = latest ? (latest.ms_end_date - Date.today).to_i : nil
      gender    = case m.mmbr_gender
                  when 'M' then 'Male'
                  when 'F' then 'Female'
                  when 'Oth' then 'Other'
                  else '—' end
      plan_name   = plan ? plan.plan_name.to_s : ''
      amount      = latest ? latest.ms_amount_paid.to_i : nil
      pay_mode    = (latest && latest.ms_payment_mode.present?) ? latest.ms_payment_mode.to_s.upcase : ''
      valid_till  = latest ? latest.ms_end_date.strftime("%d-%b-%Y") : ''
      status_text = latest.nil? ? 'No Sub' : (is_active ? 'Active' : 'Expired')

      { m: m, latest: latest, plan_name: plan_name, gender: gender, amount: amount,
        pay_mode: pay_mode, valid_till: valid_till, days_left: days_left,
        is_active: is_active, status_text: status_text,
        haystack: [m.mmbr_code, m.mmbr_name, m.mmbr_contact, gender, plan_name,
                   amount, pay_mode, valid_till, status_text].join(" ").downcase }
    end

    # --- global search (all columns) ---
    rows = rows.select { |r| r[:haystack].include?(search) } if search.present?
    records_filtered = rows.size

    # --- sort + paginate ---
    rows      = sort_member_rows(rows, ord_idx, ord_dir)
    page_rows = rows[start, length] || []

    # --- build the JSON cells (HTML allowed) ---
    data = page_rows.each_with_index.map do |r, idx|
      m = r[:m]
      [
        start + idx + 1,
        ERB::Util.html_escape(m.mmbr_code),
        "<a href=\"#{root_url}member_list/profile/#{m.id}\" style=\"color:inherit;text-decoration:underline;\">#{ERB::Util.html_escape(m.mmbr_name)}</a>",
        r[:gender],
        ERB::Util.html_escape(m.mmbr_contact),
        (r[:plan_name].present? ? ERB::Util.html_escape(r[:plan_name]) : "<span style='color:#aaa;'>—</span>"),
        amount_cell_html(r, vc),
        valid_till_cell_html(r),
        status_cell_html(r),
        action_cell_html(r)
      ]
    end

    render json: { draw: draw, recordsTotal: records_total,
                   recordsFiltered: records_filtered, data: data }
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
              mobileno = params[:mmbr_contact].to_s.strip
              if mobileno.length < 10
                message = "Mobile number should be 10 digits!"
                isFlags = false
              else
                duplicate = MstMembersList.where(
                  "mmbr_compcode = ? AND mmbr_contact = ? AND id != ?",
                  @compcodes, mobileno, params[:mid].to_i
                ).first
                if duplicate && duplicate.removed?
                  # Without this the message names someone staff cannot see
                  # anywhere in the list, which reads like a phantom record.
                  message = "Contact #{mobileno} belongs to '#{duplicate.mmbr_name}' (#{duplicate.mmbr_code}), who was removed from the list. Open Member List → Removed and restore them instead of adding a duplicate."
                  isFlags = false
                elsif duplicate
                  message = "Contact #{mobileno} already exists for '#{duplicate.mmbr_name}' (#{duplicate.mmbr_code}). Cannot save duplicate."
                  isFlags = false
                end
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

    # "Remove", not "delete". The row stays so every subscription, payment and
    # WhatsApp log that points at this member keeps resolving to a name; the
    # member simply stops appearing in lists and pickers. Restorable below.
    def destroy
        @compcodes = session[:loggedUserCompCode]
        member     = params[:id].to_i > 0 &&
                     MstMembersList.where("mmbr_compcode=? AND id=?", @compcodes, params[:id].to_i).first

        if member.blank?
            flash[:error] = "Member not found."
            session[:isErrorhandled] = 1
            redirect_to "#{root_url}member_list"
            return
        end

        if member.removed?
            flash[:error] = "#{member.mmbr_name} is already removed."
            session[:isErrorhandled] = 1
            redirect_to "#{root_url}member_list?view=removed"
            return
        end

        member.update_columns(
            mmbr_status:        MstMembersList::STATUS_REMOVED,
            mmbr_removed_at:    Time.current,
            mmbr_removed_by:    session[:loggedUserName].presence || 'Staff',
            mmbr_remove_reason: params[:reason].to_s.strip.presence,
            updated_at:         Time.current
        )

        # A removed member must not walk back in on a fingerprint that is still
        # enrolled, so their device mappings go inactive on the next sync.
        revoked = TrnMemberBiometricMapping.where(
            mbm_compcode:  @compcodes,
            mbm_member_id: member.id.to_s,
            mbm_is_active: 'Y'
        ).update_all(mbm_is_active: 'N', updated_at: Time.current)

        process_request_log_data("REMOVE", "Member List",
            "Member removed: #{member.mmbr_code} - #{member.mmbr_name}#{" (reason: #{params[:reason]})" if params[:reason].present?}")

        flash[:error] = "#{member.mmbr_name} removed from the list." \
                        "#{' Gym access revoked.' if revoked > 0}" \
                        " Their subscriptions and payments are untouched — see the Removed tab to restore."
        session[:isErrorhandled] = nil
        redirect_to "#{root_url}member_list"
    end

    # Puts a removed member back on the roll, fingerprints included.
    def restore
        @compcodes = session[:loggedUserCompCode]
        member     = params[:id].to_i > 0 &&
                     MstMembersList.where("mmbr_compcode=? AND id=?", @compcodes, params[:id].to_i).first

        if member.blank?
            flash[:error] = "Member not found."
            session[:isErrorhandled] = 1
            redirect_to "#{root_url}member_list?view=removed"
            return
        end

        member.update_columns(
            mmbr_status:        MstMembersList::STATUS_ON_ROLL,
            mmbr_removed_at:    nil,
            mmbr_removed_by:    nil,
            mmbr_remove_reason: nil,
            updated_at:         Time.current
        )

        # The stored fingerprint templates are still on the mapping rows, so
        # re-activating them lets the bridge push the member back to the device.
        restored = TrnMemberBiometricMapping.where(
            mbm_compcode:  @compcodes,
            mbm_member_id: member.id.to_s,
            mbm_is_active: 'N'
        ).update_all(mbm_is_active: 'Y', updated_at: Time.current)

        process_request_log_data("RESTORE", "Member List",
            "Member restored: #{member.mmbr_code} - #{member.mmbr_name}")

        flash[:error] = "#{member.mmbr_name} restored to the member list." \
                        "#{' Gym access re-enabled.' if restored > 0}"
        session[:isErrorhandled] = nil
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

  # Load ALL members alphabetically — 1 DB call
  stdob = MstMembersList
    .on_roll
    .where("mmbr_compcode = ?", @compcodes)
    .order("mmbr_name ASC")

  member_ids = stdob.map(&:id)

  # Load latest subscriptions — 1 DB call
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

  return stdob
 end

   def sort_member_rows(rows, idx, dir)
    sorted = case idx
             when 1 then rows.sort_by { |r| r[:m].mmbr_code.to_s }
             when 2 then rows.sort_by { |r| r[:m].mmbr_name.to_s.downcase }
             when 3 then rows.sort_by { |r| r[:gender].to_s }
             when 4 then rows.sort_by { |r| r[:m].mmbr_contact.to_s }
             when 5 then rows.sort_by { |r| r[:plan_name].to_s.downcase }
             when 6 then rows.sort_by { |r| r[:amount].to_i }
             when 7 then rows.sort_by { |r| r[:latest] ? r[:latest].ms_end_date : Date.new(1900) }
             when 8 then rows.sort_by { |r| r[:status_text] }
             else        rows.sort_by { |r| r[:m].mmbr_name.to_s.downcase }
             end
    dir == :desc ? sorted.reverse : sorted
  end

  def amount_cell_html(r, vc)
    return "<span style='color:#aaa;'>—</span>" unless r[:latest]
    html = "<strong>₹#{vc.number_with_delimiter(r[:amount])}</strong>"
    if r[:pay_mode].present?
      badge = (r[:pay_mode].downcase == 'cash') ? 'badge-success' : 'badge-info'
      html += " <span class=\"badge #{badge}\">#{ERB::Util.html_escape(r[:pay_mode])}</span>"
    end
    html
  end

  def valid_till_cell_html(r)
    return "<span style='color:#aaa;'>—</span>" unless r[:latest]
    html = r[:valid_till].dup
    if r[:days_left] && r[:days_left] >= 0
      cls   = r[:days_left] <= 7 ? 'badge-danger' : (r[:days_left] <= 30 ? 'badge-warning' : 'badge-success')
      label = r[:days_left] == 0 ? 'Expires today' : "#{r[:days_left]}d left"
      html += "<br/><span class=\"badge #{cls}\" style=\"font-size:10px;\">#{label}</span>"
    end
    html
  end

  def status_cell_html(r)
    if r[:m].removed?
      removed_on = r[:m].mmbr_removed_at ? r[:m].mmbr_removed_at.in_time_zone('Asia/Kolkata').strftime('%d-%b-%Y') : ''
      title = ["Removed #{removed_on}".strip,
               ("by #{r[:m].mmbr_removed_by}" if r[:m].mmbr_removed_by.present?),
               ("— #{r[:m].mmbr_remove_reason}" if r[:m].mmbr_remove_reason.present?)].compact.join(' ')
      "<span class=\"badge badge-default\" title=\"#{ERB::Util.html_escape(title)}\">Removed</span>"
    elsif r[:latest].nil?
      "<span class=\"badge badge-default\">No Sub</span>"
    elsif r[:is_active]
      "<span class=\"badge badge-success\">Active</span>"
    else
      "<span class=\"badge badge-danger\">Expired</span>"
    end
  end

  def action_cell_html(r)
    m    = r[:m]
    html = +""
    html << "<a href=\"#{root_url}member_list/profile/#{m.id}\" title=\"View profile\"><i class=\"fa fa-eye\" style=\"color:#5b9bd5;font-size:16px;margin-right:6px;\"></i></a>"

    if m.removed?
      html << "<a class=\"tblRestoreBtn\" title=\"Put this member back on the list\" " \
              "onclick=\"restoreMember(#{m.id}, '#{ERB::Util.html_escape(m.mmbr_name).gsub("'", "&#39;")}')\" " \
              "style=\"margin-left:6px;cursor:pointer;\"><i class=\"fa fa-undo\" style=\"color:#22c55e;font-size:15px;\"></i></a>"
      return html
    end

    html << "<a href=\"#{root_url}member_list/add_member/#{m.id}\" class=\"tblEditBtn\" title=\"Edit member\"><i class=\"fa fa-pencil\"></i></a>"
    html << "<a class=\"tblDelBtn\" title=\"Remove from list\" " \
            "onclick=\"removeMember(#{m.id}, '#{ERB::Util.html_escape(m.mmbr_name).gsub("'", "&#39;")}')\" " \
            "style=\"margin-left:6px;cursor:pointer;\"><i class=\"fa fa-trash-o\"></i></a>"
    if r[:latest].nil? || r[:latest].ms_end_date < Date.today
      html << "<a href=\"#{root_url}member_subscriptions/add_member_subscriptions?renew=1&member_id=#{m.id}&from=member_list\" title=\"Renew subscription\" style=\"margin-left:6px;\"><i class=\"fa fa-refresh\" style=\"color:#f0a500;font-size:16px;\"></i></a>"
    end
    html
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
