class TrainerListController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:format_oblig_date,:get_dob_calculate
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @trainer_list = get_trainer_list()
        @trainer     = nil
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        printPath     =  "trainer_list/1_prt_trainer_list.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'trainer'
              
              @trainerdetail   = print_trainer_list()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = FacultyPdf.new(@trainerdetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_trainer_list.pdf", :type => "application/pdf", :disposition => "inline"
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
      elsif  params[:identity] != nil && params[:identity] != '' && params[:identity] ==  'TRAINER'
        create();
        return 
      end
    end

    def add_trainer
        @compcodes      = session[:loggedUserCompCode] 
        @Lastcode=generate_code(table: MstTrainerList, column: "trn_code", prefix: "M", compcode: session[:loggedUserCompCode])
        @trainer     = nil
        if params[:id].to_i>0
            @trainer = MstTrainerList.where("trn_compcode=? AND id=?",@compcodes,params[:id]).first
            
        end
    end

    def referesh_trainer_list
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        session[:req_member_list] = nil
        isFlags = true
        redirect_to "#{root_url}trainer_list"
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
          if params[:trn_code].to_s.blank?
             message =  "Member Code is Required"
             isFlags = false
          elsif
             params[:trn_name].to_s.blank?
             message =  "Name is Required"
             isFlags = false
          elsif
            params[:trn_gender].to_s.blank?
            message =  "Gender is Required"
            isFlags = false
          elsif
             params[:trn_dob].to_s.blank?
             message =  "Date of Birth is Required"
             isFlags = false
            elsif
              params[:trn_contact].to_s.blank?
              message =  "Contact No. is Required"
              isFlags = false
          end

            currentgrp =  params[:cur_trn_code].to_s.strip
            newgroup   =  params[:trn_code].to_s.strip
            mobileno   =  params[:trn_contact].to_s.strip
            if mobileno.length<10
                message = "Mobile number should be 10 digits!"
                isFlags = false
            end 

              if params[:mid].to_i>0
                 if currentgrp.to_s.downcase != newgroup.to_s.downcase
                     chkgrpobj   = MstMembersList.where("trn_compcode=? AND LOWER(trn_code)=? ",@compcodes,newgroup.to_s.downcase)
                     if chkgrpobj.length>0
                         message = "Member Code already exist!"
                         isFlags        = false
                     end
                 end
         
               if isFlags
                     chkgrpobj   = MstMembersList.where("trn_compcode=? AND id=?",@compcodes,mid).first
                     if chkgrpobj
                      profileid    = chkgrpobj.id
                         chkgrpobj.update(members_params)
                        message = "Data updated successfully"
                         isFlags       = true
                         modulename = "Member List"
                         description = "Member List Update: #{params[:trn_code]}"
                         process_request_log_data("UPDATE", modulename, description)
                     end
               end
             else
                 chkgrpobj   = MstMembersList.where("trn_compcode=? AND LOWER(trn_code)=?",@compcodes,newgroup.to_s.downcase)
                 if chkgrpobj.length>0
                  message = "Member Code already exist!"
                  isFlags        = false
                 end
                   if isFlags
                       savegrp = MstMembersList.new(_params)
                       if savegrp.save
                           profileid    = savegrp.id.to_i
                          chkgrpobjx   = MstMembersList.where("trn_compcode=? AND id=?",@compcodes,profileid).first
                           message = "Data saved successfully"
                           isFlags       = true
                           modulename = "Member List"
                           description = "Member List Save: #{params[:trn_code]}"
                           process_request_log_data("SAVE", modulename, description)
                      
                       end
                   end
         
             end
             if !isFlags
                 session[:isErrorhandled] = 1
                 session[:postedpamams]   = nil
                #  session[:sess_fclty_img] = params[:fclty_img]
                 session[:sess_trn_code] = params[:trn_code]
                 session[:sess_trn_name] = params[:trn_name]
                 session[:sess_trn_gender] = params[:trn_gender]
                 session[:sess_trn_dob] = params[:trn_dob]
                 session[:sess_trn_join_date] = params[:trn_join_date]
                 session[:sess_trn_leave_date] = params[:trn_leave_date]
                 session[:sess_trn_mrtl_stats] = params[:trn_mrtl_stats]
                 session[:sess_trn_aadhaar] = params[:trn_aadhaar]
                 session[:sess_trn_pan] = params[:trn_pan]
                 session[:sess_trn_contact] = params[:trn_contact]
                 session[:sess_trn_addr1] = params[:trn_addr1]
                 session[:sess_trn_addr2] = params[:trn_addr2]
                 session[:sess_trn_city] = params[:trn_city]
                 session[:sess_trn_email] = params[:trn_email]
                 session[:sess_trn_father] = params[:trn_father]
                 session[:sess_trn_mother] = params[:trn_mother]

             else
                 session[:isErrorhandled] = nil
                 session[:postedpamams]   = nil
                #  session[:sess_fclty_img] = nil
                 session[:sess_trn_code] = nil
                 session[:sess_trn_name] = nil
                 session[:sess_trn_gender] = nil
                 session[:sess_trn_dob] = nil
                 session[:sess_trn_join_date] = nil
                 session[:sess_trn_leave_date] = nil
                 session[:sess_trn_mrtl_stats] = nil
                 session[:sess_trn_aadhaar] = nil
                 session[:sess_trn_pan] = nil
                 session[:sess_trn_contact] = nil
                 session[:sess_trn_addr1] =nil
                 session[:sess_trn_addr2] = nil
                 session[:sess_trn_city] = nil
                 session[:sess_trn_email] = nil
                 session[:sess_trn_father] =nil
                 session[:sess_trn_mother] = nil

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
            @ListSate =  MstMembersList.where("trn_compcode=? AND id=?", @compcodes,params[:id].to_i).first
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
          iswhere       = "trn_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( trn_code LIKE '%#{filter_search}%' OR trn_name LIKE '%#{filter_search}%')"
            @member_list_search       = filter_search
            session[:req_member_list] = filter_search
          end    
          
        stdob =  MstMembersList.where(iswhere).order("trn_code ASC")
        return stdob
    end

    private
    def members_params
        params[:trn_compcode]     = session[:loggedUserCompCode] 
                params[:trn_entry_date] = Date.today
        params.permit(:trn_compcode,:trn_city,:trn_mother,:trn_father,:trn_contact,:trn_email,:trn_addr1,:trn_addr2,:trn_mrtl_stats,:trn_aadhaar,:trn_code,:trn_name,:trn_gender,:trn_dob,:trn_join_date,:trn_leave_date,:trn_entry_date)
                    # chkgrpobj   = MstFaculty.where("fclty_compcode=? ",@compcodes)

    end

    private
    def generate_regularization_series
        @compcodes      = session[:loggedUserCompCode]
         @isCode     = 0
         @Startx     = '0000' 
         @recCodes  = MstMembersList.where(["trn_compcode = ? AND trn_code <>'' ", @compcodes]).order('trn_code DESC').first
         if @recCodes
           @isCode    = @recCodes.trn_code.to_i
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
