include GlobalCodeGenerator

class StaffListController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:format_oblig_date,:get_dob_calculate
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @staff_list = get_staff_list()
        @member     = nil
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        printPath     =  "staff_list/1_prt_staff_list.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'staff'
              
              @staffdetail   = print_staff_list()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = FacultyPdf.new(@staffdetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_staff_list.pdf", :type => "application/pdf", :disposition => "inline"
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
      elsif  params[:identity] != nil && params[:identity] != '' && params[:identity] ==  'STAFF'
        create();
        return 
      end
    end

    def add_staff
        @compcodes      = session[:loggedUserCompCode] 
        @Lastcode=generate_code(table: MstStaffList,column: "stf_code",prefix: "STF",compcode: session[:loggedUserCompCode])
        @staff     = nil
        if params[:id].to_i>0
            @staff = MstStaffList.where("stf_compcode=? AND id=?",@compcodes,params[:id]).first
            
        end
    end

    def referesh_staff_list
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        session[:req_staff_list] = nil
        isFlags = true
        redirect_to "#{root_url}staff_list"
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
          if params[:stf_code].to_s.blank?
             message =  "Staff Code is Required"
             isFlags = false
          elsif
             params[:stf_name].to_s.blank?
             message =  "Name is Required"
             isFlags = false
          elsif
            params[:stf_gender].to_s.blank?
            message =  "Gender is Required"
            isFlags = false
          elsif
              params[:stf_contact].to_s.blank?
              message =  "Contact No. is Required"
              isFlags = false
          end

            currentgrp =  params[:cur_stf_code].to_s.strip
            newgroup   =  params[:stf_code].to_s.strip
            mobileno   =  params[:stf_contact].to_s.strip
            if mobileno.length<10
                message = "Mobile number should be 10 digits!"
                isFlags = false
            end 

              if params[:mid].to_i>0
                 if currentgrp.to_s.downcase != newgroup.to_s.downcase
                     chkgrpobj   = MstStaffList.where("stf_compcode=? AND LOWER(stf_code)=? ",@compcodes,newgroup.to_s.downcase)
                     if chkgrpobj.length>0
                         message = "Staff Code already exist!"
                         isFlags        = false
                     end
                 end
         
               if isFlags
                     chkgrpobj   = MstStaffList.where("stf_compcode=? AND id=?",@compcodes,mid).first
                     if chkgrpobj
                      profileid    = chkgrpobj.id
                         chkgrpobj.update(staff_params)
                        message = "Data updated successfully"
                         isFlags       = true
                         modulename = "Staff List"
                         description = "Staff List Update: #{params[:stf_code]}"
                         process_request_log_data("UPDATE", modulename, description)
                     end
               end
             else
                 chkgrpobj   = MstStaffList.where("stf_compcode=? AND LOWER(stf_code)=?",@compcodes,newgroup.to_s.downcase)
                 if chkgrpobj.length>0
                  message = "Staff Code already exist!"
                  isFlags        = false
                 end
                   if isFlags
                       savegrp = MstStaffList.new(staff_params)
                       if savegrp.save
                           profileid    = savegrp.id.to_i
                          chkgrpobjx   = MstStaffList.where("stf_compcode=? AND id=?",@compcodes,profileid).first
                           message = "Data saved successfully"
                           isFlags       = true
                           modulename = "Staff List"
                           description = "Staff List Save: #{params[:stf_code]}"
                           process_request_log_data("SAVE", modulename, description)
                      
                       end
                   end
         
             end
             if !isFlags
                 session[:isErrorhandled] = 1
                 session[:postedpamams]   = nil
                #  session[:sess_fclty_img] = params[:fclty_img]
                 session[:sess_stf_code] = params[:stf_code]
                 session[:sess_stf_name] = params[:stf_name]
                 session[:sess_stf_gender] = params[:stf_gender]
                 session[:sess_stf_dob] = params[:stf_dob]
                 session[:sess_stf_designation] = params[:stf_designation]
                 session[:sess_stf_join_date] = params[:stf_join_date]
                 session[:sess_stf_leave_date] = params[:stf_leave_date]
                 session[:sess_stf_contact] = params[:stf_contact]
                 session[:sess_stf_email] = params[:stf_email]
                 session[:sess_stf_address1] = params[:stf_address1]
                 session[:sess_stf_address2] = params[:stf_address2]
                 session[:sess_stf_aadhaar] = params[:stf_aadhaar]
                 session[:sess_stf_status] = params[:stf_status]

             else
                 session[:isErrorhandled] = nil
                 session[:postedpamams]   = nil
                #  session[:sess_fclty_img] = nil
                 session[:sess_stf_code] = nil
                 session[:sess_stf_name] = nil
                 session[:sess_stf_gender] = nil
                 session[:sess_stf_dob] = nil
                 session[:sess_stf_designation] = nil
                 session[:sess_stf_join_date] = nil
                 session[:sess_stf_leave_date] = nil
                 session[:sess_stf_contact] = nil
                 session[:sess_stf_email] = nil
                 session[:sess_stf_address1] = nil
                 session[:sess_stf_address2] = nil
                 session[:sess_stf_aadhaar] = nil
                 session[:sess_stf_status] = nil

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
            @ListSate =  MstStaffList.where("stf_compcode=? AND id=?", @compcodes,params[:id].to_i).first
               if @ListSate
                     @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
       end
       redirect_to "#{root_url}staff_list"
    end

    private
    def get_staff_list
        @compcodes      = session[:loggedUserCompCode] 
        
        if params[:page].to_i >0
            pages = params[:page]
            else
            pages = 1
            end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
            #  session[:req_faculty_list] = nil
          # end
          filter_search = params[:staff_list] !=nil && params[:staff_list] != '' ? params[:staff_list].to_s.strip : session[:req_staff_list].to_s.strip       
          iswhere       = "stf_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( stf_code LIKE '%#{filter_search}%' OR stf_name LIKE '%#{filter_search}%')"
            @staff_list_search       = filter_search
            session[:req_staff_list] = filter_search
          end    
          
        stdob =  MstStaffList.where(iswhere).order("stf_code ASC")
        return stdob
    end

    private
    def staff_params
        params[:stf_compcode]     = session[:loggedUserCompCode] 
       stf_leave_date          = params[:stf_leave_date] !=nil && params[:stf_leave_date]!='' ? params[:stf_leave_date] : 0
              stf_join_date          = params[:stf_join_date] !=nil && params[:stf_join_date]!='' ? params[:stf_join_date] : 0
        params.permit(:stf_compcode,:stf_code,:stf_name,:stf_gender,:stf_dob,:stf_designation,:stf_join_date,:stf_leave_date,:stf_contact,:stf_email,:stf_address1,:stf_address2,:stf_aadhaar,:stf_status)
                    # chkgrpobj   = MstFaculty.where("fclty_compcode=? ",@compcodes)

    end

    private
    def generate_regularization_series
        @compcodes      = session[:loggedUserCompCode]
         @isCode     = 0
         @Startx     = '0000' 
         @recCodes  = MstStaffList.where(["stf_compcode = ? AND stf_code <>'' ", @compcodes]).order('stf_code DESC').first
         if @recCodes
           @isCode    = @recCodes.stf_code.to_i
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
