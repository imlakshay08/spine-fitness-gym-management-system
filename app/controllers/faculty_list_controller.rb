

class FacultyListController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:format_oblig_date,:get_dob_calculate
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @faculty_list = get_faculty_list()
        @faculty     = nil
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first

        if params[:id].to_i>0
            @faculty = MstFaculty.where("fclty_compcode=? AND id=?",@compcodes,params[:id]).first

        end
        printPath     =  "faculty_list/1_prt_faculty_list.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'faculty'
              
              @facultydetail   = print_faculty_list()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = FacultyPdf.new(@facultydetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_faculty_list.pdf", :type => "application/pdf", :disposition => "inline"
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

    def add_faculty
        @compcodes      = session[:loggedUserCompCode] 
        @faculty     = nil
        if params[:id].to_i>0
            @faculty = MstFaculty.where("fclty_compcode=? AND id=?",@compcodes,params[:id]).first
            
        end
    end

    def referesh_faculty_list
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        session[:req_faculty_list] = nil
        isFlags = true
        redirect_to "#{root_url}faculty_list"
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
          if params[:fclty_code].to_s.blank?
             message =  "Faculty Code is Required"
             isFlags = false
          elsif
             params[:fclty_name].to_s.blank?
             message =  "Name is Required"
             isFlags = false
          elsif
            params[:fclty_gender].to_s.blank?
            message =  "Gender is Required"
            isFlags = false
          elsif
             params[:fclty_dob].to_s.blank?
             message =  "Date of Birth is Required"
             isFlags = false
            elsif
              params[:fclty_contact].to_s.blank?
              message =  "Contact No. is Required"
              isFlags = false
          end

            currentgrp =  params[:cur_fclty_code].to_s.strip
            newgroup   =  params[:fclty_code].to_s.strip
            mobileno   =  params[:fclty_contact].to_s.strip
            if mobileno.length<10
                message = "Mobile number should be 10 digits!"
                isFlags = false
            end 

              if params[:mid].to_i>0
                 if currentgrp.to_s.downcase != newgroup.to_s.downcase
                     chkgrpobj   = MstFaculty.where("fclty_compcode=? AND LOWER(fclty_code)=? ",@compcodes,newgroup.to_s.downcase)
                     if chkgrpobj.length>0
                         message = "Faculty Code already exist!"
                         isFlags        = false
                     end
                 end
         
               if isFlags
                     chkgrpobj   = MstFaculty.where("fclty_compcode=? AND id=?",@compcodes,mid).first
                     if chkgrpobj
                      profileid    = chkgrpobj.id
                      profileimage = chkgrpobj.fclty_img
                      signimages   = chkgrpobj.fclty_signature
                         chkgrpobj.update(faculty_params)
                        message = "Data updated successfully"
                         isFlags       = true
                         modulename = "Faculty List"
                         description = "Faculty List Update: #{params[:fclty_code]}"
                         process_request_log_data("UPDATE", modulename, description)
                     end
               end
             else
                 chkgrpobj   = MstFaculty.where("fclty_compcode=? AND LOWER(fclty_code)=?",@compcodes,newgroup.to_s.downcase)
                 if chkgrpobj.length>0
                  message = "Faculty Code already exist!"
                  isFlags        = false
                 end
                   if isFlags
                       savegrp = MstFaculty.new(faculty_params)
                       if savegrp.save
                           profileid    = savegrp.id.to_i
                          chkgrpobjx   = MstFaculty.select("fclty_signature,fclty_img").where("fclty_compcode=? AND id=?",@compcodes,profileid).first
                          if chkgrpobjx                            
                              profileimage = chkgrpobjx.fclty_img
                              signimages   = chkgrpobjx.fclty_signature
                          end
                           message = "Data saved successfully"
                           isFlags       = true
                           modulename = "Faculty List"
                           description = "Faculty List Save: #{params[:fclty_code]}"
                           process_request_log_data("SAVE", modulename, description)
                      
                       end
                   end
         
             end
             if !isFlags
                 session[:isErrorhandled] = 1
                 session[:postedpamams]   = nil
                #  session[:sess_fclty_img] = params[:fclty_img]
                 session[:sess_fclty_code] = params[:fclty_code]
                 session[:sess_fclty_name] = params[:fclty_name]
                 session[:sess_fclty_gender] = params[:fclty_gender]
                 session[:sess_fclty_dob] = params[:fclty_dob]
                 session[:sess_fclty_join_date] = params[:fclty_join_date]
                 session[:sess_fclty_leave_date] = params[:fclty_leave_date]
                 session[:sess_fclty_mrtl_stats] = params[:fclty_mrtl_stats]
                 session[:sess_fclty_aadhaar] = params[:fclty_aadhaar]
                 session[:sess_fclty_pan] = params[:fclty_pan]
                 session[:sess_fclty_contact] = params[:fclty_contact]
                 session[:sess_fclty_addr1] = params[:fclty_addr1]
                 session[:sess_fclty_addr2] = params[:fclty_addr2]
                 session[:sess_fclty_city] = params[:fclty_city]
                 session[:sess_fclty_email] = params[:fclty_email]
                 session[:sess_fclty_father] = params[:fclty_father]
                 session[:sess_fclty_mother] = params[:fclty_mother]
                 session[:sess_fclty_spouse] = params[:fclty_spouse]
                 session[:sess_fclty_desig] = params[:fclty_desig]
                 session[:sess_fclty_qlf] = params[:fclty_qlf]

             else
                 session[:isErrorhandled] = nil
                 session[:postedpamams]   = nil
                #  session[:sess_fclty_img] = nil
                 session[:sess_fclty_code] = nil
                 session[:sess_fclty_name] = nil
                 session[:sess_fclty_gender] = nil
                 session[:sess_fclty_dob] = nil
                 session[:sess_fclty_join_date] = nil
                 session[:sess_fclty_leave_date] = nil
                 session[:sess_fclty_mrtl_stats] = nil
                 session[:sess_fclty_aadhaar] = nil
                 session[:sess_fclty_pan] = nil
                 session[:sess_fclty_contact] = nil
                 session[:sess_fclty_addr1] =nil
                 session[:sess_fclty_addr2] = nil
                 session[:sess_fclty_city] = nil
                 session[:sess_fclty_email] = nil
                 session[:sess_fclty_father] =nil
                 session[:sess_fclty_mother] = nil
                 session[:sess_fclty_spouse] = nil
                 session[:sess_fclty_desig] = nil
                 session[:sess_fclty_qlf] = nil

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
            format.json { render :json => {  "message"=>message,:mdid=>mdid,:mdfiles=>mdfiles,:profileid=>profileid,:profileimage=>profileimage,:signimages=>signimages,:status=>isFlags} }
          end
    end

    def destroy
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i >0
            @ListSate =  MstFaculty.where("fclty_compcode=? AND id=?", @compcodes,params[:id].to_i).first
               if @ListSate
                     @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
       end
       redirect_to "#{root_url}faculty_list"
    end

    private
    def get_faculty_list
        @compcodes      = session[:loggedUserCompCode] 
        
        if params[:page].to_i >0
            pages = params[:page]
            else
            pages = 1
            end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
            #  session[:req_faculty_list] = nil
          # end
          filter_search = params[:faculty_list] !=nil && params[:faculty_list] != '' ? params[:faculty_list].to_s.strip : session[:req_faculty_list].to_s.strip       
          iswhere       = "fclty_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( fclty_code LIKE '%#{filter_search}%' OR fclty_name LIKE '%#{filter_search}%')"
            @faculty_list_search       = filter_search
            session[:req_faculty_list] = filter_search
          end    
          
        stdob =  MstFaculty.where(iswhere).order("fclty_code ASC")
        return stdob
    end

    private
    def faculty_params
        params[:fclty_compcode]     = session[:loggedUserCompCode] 
        imgfolder = "faculty"
        attachfile = ""
        signattach = ""
        signs      = "facultysign"
        fclty_supann_date = '0'
        cursignature      = params[:cursignature]
      facultyimgeId = params[:facultyimgeId]

           if params[:fclty_signature].present?        
          if params[:mid].to_i > 0          
                if cursignature.to_s.present?
                    signs_path = "#{params[:fclty_compcode]}/facultysign"
                    bunny_delete_storage_file(cursignature,signs_path)                  
                end
          end         
       signattach = process_without_base64_files(params[:fclty_signature], params[:cursignature], signs)   
    
    end
    if signattach.to_s.blank?
        if cursignature.to_s.present?
          signattach = cursignature
        end      
    end 
    
      params[:fclty_signature] = signattach

        if params[:new_fac_img].present?
         
          attachfile = process_files_pos(params[:new_fac_img], params[:facultyimgeId], imgfolder)
          # image_list() # Ensure this method is defined

        end
      if attachfile.to_s.blank?
          if facultyimgeId.to_s.present?
              attachfile = facultyimgeId
          end      
      end
      params[:fclty_img]      = attachfile
      params[:fclty_valid_upto]   = params[:fclty_valid_upto] !=nil && params[:fclty_valid_upto] !='' ? params[:fclty_valid_upto] : 0
        params.permit(:fclty_compcode,:fclty_pan,:fclty_spouse,:fclty_desig,:fclty_qlf,:fclty_supann_date,:fclty_img,:fclty_city,:fclty_mother,:fclty_father,:fclty_contact,:fclty_email,:fclty_addr1,:fclty_addr2,:fclty_mrtl_stats,:fclty_aadhaar,:fclty_code,:fclty_name,:fclty_gender,:fclty_dob,:fclty_join_date,:fclty_leave_date,:fclty_aebas_id,:fclty_employee_code,:fclty_blood_group,:fclty_cghs_id,:fclty_emergency_no,:fclty_valid_upto,:fclty_signature,:fclty_paylevel)
                    # chkgrpobj   = MstFaculty.where("fclty_compcode=? ",@compcodes)

    end

    private
    def bunny_storage_connection
      Faraday.new(url: 'https://storage.bunnycdn.com') do |conn|
        conn.headers['AccessKey'] = '52525a0c-43cc-4681-bed88fbebfa6-34f3-462d'
        conn.headers['Content-Type'] = 'application/octet-stream'
        conn.headers['Accept'] = 'application/json'
        conn.adapter Faraday.default_adapter
      end
    end
	
    private
    def print_faculty_list
      @compcodes      = session[:loggedUserCompCode] 
      iswhere         = "fclty_compcode ='#{@compcodes}'"
      filter_search   = session[:req_faculty_list]   
      if filter_search !=nil && filter_search !=''
          iswhere +=" AND ( fclty_code LIKE '%#{filter_search}%' OR fclty_name LIKE '%#{filter_search}%')"
        end    
      stdob =  MstFaculty.where(iswhere).order("fclty_code ASC")
      return stdob
    end

    private
    def get_birth_date_calculation
        newdate = ''
        isflags = false
        myages = ''
        sewaleft = ""
        if params[:birthdate] !=nil && params[:birthdate] !=''
 
               newdate   = Date.parse(params[:birthdate].to_s)+62.years
               newdate   = format_oblig_date(newdate)
               isflags = true
               myages   = get_dob_calculate(year_month_days_formatted(params[:birthdate]))
               sewaleft = get_dob_calculate(year_month_days_formatted(newdate))
               sewaleft  = sewaleft.to_s.delete("-")
        end
         respond_to do |format|
              format.json { render :json => { 'data'=>newdate, "message"=>'','ages'=>myages,'leftsewa'=>sewaleft,:status=>isflags} }
            end
    end
 
end
