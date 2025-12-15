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
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        session[:req_member_list] = nil
        isFlags = true
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

    private
    def get_member_list
        @compcodes      = session[:loggedUserCompCode] 
        
        if params[:page].to_i >0
            pages = params[:page]
            else
            pages = 1
            end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
            #  session[:req_faculty_list] = nil
          # end
          filter_search = params[:member_list] !=nil && params[:member_list] != '' ? params[:member_list].to_s.strip : session[:req_member_list].to_s.strip       
          iswhere       = "mmbr_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( mmbr_code LIKE '%#{filter_search}%' OR mmbr_name LIKE '%#{filter_search}%')"
            @member_list_search       = filter_search
            session[:req_member_list] = filter_search
          end    
          
        stdob =  MstMembersList.where(iswhere).order("mmbr_code ASC")
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
