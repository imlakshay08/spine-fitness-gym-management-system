class StudentListController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    helper_method :get_course_student,:get_general_information,:get_personal_information,:get_optional_subject
    def index
      # download_images_for_all_students
        @compcodes        = session[:loggedUserCompCode] 
        @student_list     = get_student_list()
        @CourseList       = MstCourseList.where("crse_compcode =? AND crse_code != ''  ",@compcodes)
        @student_gen_dtls = MstStdntGenDtl.where("stdnt_gn_compcode=? AND id=?",@compcodes,params[:id])
        @student_dtls     = MstStudentDtl.where("stdnt_dtl_compcode=? AND id=?",@compcodes,params[:id])
        @printPath     =  "student_list/1_prt_student_list.pdf"
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        if params[:id] != nil && params[:id] != ''
          docsid  = params[:id].to_s.split("_")
          rooturl       = "#{root_url}"
          if  docsid[1] == 'prt'
            
            @studentdetail   = print_student_list()
                respond_to do |format|
                    format.html
                    format.pdf do
                       pdf = StudentlistPdf.new(@studentdetail, @compDetail, rooturl)
                       send_data pdf.render,:filename => "1_student_list.pdf", :type => "application/pdf", :disposition => "inline"
                    end
                  end

              end
          end
        
    end

    def student_admission
        @compcodes      = session[:loggedUserCompCode] 
        @studentadm     = nil
        @CourseList     = MstCourseList.where("crse_compcode =? AND crse_descp != ''  ",@compcodes)
        @SubjectList    = MstSubjectList.where("sub_compcode=? AND sub_isoptional='Y' AND sub_name != ''  ",@compcodes)
        @Listsemester = []
        @CourseList.each do |course|
          duration = course.crse_duration
          @Listsemester += get_semester_list(duration)
        end
        
        @Listsemester.uniq!
        @CategoryList   = MstCategoryList.where("cat_compcode =? AND cat_descp != ''  ",@compcodes)
        if params[:id].to_i>0
            @studentadm = MstStudent.where("stdnt_compcode=? AND id=?",@compcodes,params[:id]).first
            @selected_semester = @subject.stdnt_gn_cur_sem if @subject.present?

            if @studentadm
              @studentadmdtl          = get_personal_information(@compcodes,@studentadm.stdnt_reg_no)
              @allstudentadmfam       = get_family_information(@compcodes,@studentadm.stdnt_reg_no)
              @studentadmgen          = get_general_information(@compcodes,@studentadm.stdnt_reg_no)
              @selected_semester = @studentadmgen.stdnt_gn_cur_sem if @studentadmgen.present?

              #@studentadmdtl          = MstStudentDtl.where("stdnt_dtl_compcode=? AND id=?",@compcodes,params[:id]).first
              @studentadmfam          = MstStdntFamily.where("stdnt_fam_compcode=? AND id=?",@compcodes,params[:id]).first
              #@studentadmgen          = MstStdntGenDtl.where("stdnt_gn_compcode=? AND id=?",@compcodes,params[:id]).first
        end     
            
         end   
    end     

    def ajax_process
        @compCodes       = session[:loggedUserCompCode]
        if params[:identity] != nil && params[:identity] != '' && params[:identity] == 'STDNT'
          create();
            return
        elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'PRNTDTLS'
            save_parent_details();
            return
        elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'GNRLDTLS'
            save_general_details();
            return
        elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'SEMESTER'
              get_semesters();
              return
        end
    end

    def create
        @compcodes      = session[:loggedUserCompCode] 
        isFlags      = true
        mid          = params[:mid]
        message      = ""
        dtfiles      = []
        profileid    = ""
        profileimage = ""
        signimages   = ""
        mdid         = ""
        mdfiles      = ""
        # begin
            if params[:stdnt_reg_no].to_s.blank?
                 message =  "Registration No. is Required"
                isFlags = false
            elsif params[:stdnt_reg_date].to_s.blank?
              message =  "Registration Date is Required"
                isFlags = false  
            elsif params[:stdnt_fname].to_s.blank?
              message =  "First Name is Required"
                isFlags = false
            elsif params[:stdnt_dob].to_s.blank?
              message = "Date of Birth is Required"
                isFlags = false
            elsif params[:stdnt_gender].to_s.blank?
                  message = "Gender is Required"
                  isFlags = false
            
            end
         if isFlags   
            newgroup     =  params[:stdnt_reg_no].to_s.strip
            curregistno  = params[:curregistno].to_s.strip
            if params[:mid].to_i>0
              
                if newgroup.to_s.downcase !=curregistno.to_s.downcase
                      chkgrpobj   = MstStudent.where("stdnt_compcode=? AND LOWER(stdnt_reg_no)=?",@compcodes,newgroup.to_s.downcase)
                      if chkgrpobj.length>0
                        message = "The registration number you entered is already taken."
                      isFlags        = false
                      end

                end
              if isFlags
                    chkgrpobj   = MstStudent.where("stdnt_compcode=? AND id=?",@compcodes,mid).first
                    if chkgrpobj
                      profileid    = chkgrpobj.id
                      profileimage = chkgrpobj.stdnt_img
                      signimages   = chkgrpobj.stdnt_signature
                      
                        chkgrpobj.update(student_params)
                        mdid,mdfiles =  save_student_details()
                        message       = "Data updated successfully"
                        isFlags       = true
                        modulename    = "Student List"
                        description   = "Student List Update: #{params[:stdnt_reg_no]}"
                        process_request_log_data("UPDATE", modulename, description)
                    end
              end
            else
                chkgrpobj   = MstStudent.where("stdnt_compcode=? AND LOWER(stdnt_reg_no)=?",@compcodes,newgroup.to_s.downcase)
                if chkgrpobj.length>0
                  message = "The registration number you entered is already taken."
                isFlags        = false
                end
                  if isFlags
                      @savegrp = MstStudent.new(student_params)
                      if @savegrp.save
                          profileid    = @savegrp.id.to_i
                          chkgrpobjx   = MstStudent.select("stdnt_signature,stdnt_img").where("stdnt_compcode=? AND id=?",@compcodes,profileid).first
                          if chkgrpobjx                            
                              profileimage = chkgrpobjx.stdnt_img
                              signimages   = chkgrpobjx.stdnt_signature
                          end

                          mdid,mdfiles =  save_student_details()
                          message     = "Data saved successfully"
                          isFlags     = true
                          modulename  = "Student List"
                          description = "Student List Save: #{params[:stdnt_reg_no]}"
                          process_request_log_data("SAVE", modulename, description)
                    
                      end
                  end
        
            end
                
          end
          if !isFlags
            session[:isErrorhandled] = 1
            #session[:postedpamams]   = params
        else
            session[:isErrorhandled] = nil
            session[:postedpamams]   = nil
            isFlags = true
        end
        # rescue Exception => exc
        #     message = "ERROR: #{exc.message}"
        #     session[:isErrorhandled] = 1
        #     isFlags = false
        # end
          respond_to do |format|
            format.json { render :json => {  "message"=>message,:mdid=>mdid,:mdfiles=>mdfiles,:profileid=>profileid,:profileimage=>profileimage,:signimages=>signimages,:status=>isFlags} }
          end

    end

    def referesh_student_list
      compcodes =  session[:loggedUserCompCode]
      session[:isErrorhandled] = nil
      session[:postedpamams]   = nil
      session[:req_student_list] = nil
      session[:req_course_search] = nil
      session[:req_year_search] = nil

      isFlags = true
      redirect_to "#{root_url}student_list"
    end

    def deleteparent
      compcodes = session[:loggedUserCompCode]
      
      if params[:id].to_i > 0
        # Find the parent record to delete
        delobj = MstStdntFamily.where("stdnt_fam_compcode = ? AND id = ?", compcodes, params[:id].to_i).first
        
        if delobj
          # Retrieve the stdnt_fam_code from the parent record
          stdnt_fam_code = delobj.stdnt_fam_code
          
          # Find the main student record in MstStudent using stdnt_fam_code (stdnt_reg_no)
          student = MstStudent.find_by(stdnt_reg_no: stdnt_fam_code, stdnt_compcode: compcodes)
          
          # Delete the parent record if found
          if delobj.destroy
            flash[:notice] = "Parent detail deleted successfully."
            session[:isErrorhandled] = nil
          end
    
          # Redirect to the main student admission page using the found student's ID
          if student
            redirect_to "#{root_url}student_list/student_admission/#{student.id}"
          else
            flash[:alert] = "Associated student not found."
            redirect_to "#{root_url}student_list/student_admission"
          end
        else
          flash[:alert] = "Parent detail not found."
          redirect_to "#{root_url}student_list/student_admission"
        end
      else
        flash[:alert] = "Invalid ID."
        redirect_to "#{root_url}student_list/student_admission"
      end
    end
    
    def get_semesters
      @compcodes = session[:loggedUserCompCode]
      course_code = params[:course_code]
      semesters = []
      isflags = false
      course = MstCourseList.select("crse_duration").where("crse_compcode = ? AND id = ?", @compcodes, course_code).first
    
      if course
        duration = course.crse_duration
        case duration
        when '6 Months'
          # No semesters for 6-month courses
          semesters = [1]
          isflags = true
        when '1 Year'
          semesters = [1, 2]
          isflags = true
        when '2 Year'
          semesters = [1, 2, 3, 4]
          isflags = true
        when '3 Year'
          semesters = [1, 2, 3, 4, 5, 6]
          isflags = true
        else
          # Handle any unexpected cases
          semesters = []
          isflags = false
        end
      end
    
      respond_to do |format|
        format.json { render json: { 'data' => semesters, 'message' => '', status: isflags } }
      end
    end
    
  
    def get_semester_list(duration)
      case duration
      when '6 Months'
        [1]
      when '1 Year'
        [1, 2]
      when '2 Year'
        [1, 2, 3, 4]
      when '3 Year'
        [1, 2, 3, 4, 5, 6]
      else
        []
      end
    end


    def destroy
        compcodes =  session[:loggedUserCompCode]
        params[:stdnt_compcode]	    = @compcodes
        if params[:id].to_i >0
                @ListSate =  MstStudent.where("stdnt_compcode=? AND id=?", compcodes,params[:id].to_i).first
             if @ListSate
                # checkdelstatus = check_deleted_option(@ListSate.stdnt_reg_no)
                 # if checkdelstatus
                       #flash[:error] =  "The data could not be deleted because the registration number already exists in other related areas."
                      #session[:isErrorhandled] = 1
               # else
                        if  @ListSate.destroy
                            flash[:error] =  "Data deleted successfully."
                            isFlags       =  true
                            session[:isErrorhandled] = nil
                        end

               #  end
                 
              end
       end
       redirect_to "#{root_url}student_list"
    end


    def check_deleted_option(stdnt_reg_no)
        compcodes   =  session[:loggedUserCompCode]
        isFlags    = false
        stdpersonal    = get_personal_information(compcodes,stdnt_reg_no)
        if stdpersonal
          isFlags = true
        end
        if !isFlags
            stdfamily      = get_family_information(compcodes,stdnt_reg_no)
            if stdfamily.length >0
              isFlags = true
            end
        end
        if !isFlags
            stdgenral      = get_general_information(compcodes,stdnt_reg_no)
            if stdgenral
              isFlags = true
            end
        end            
        return isFlags
    end

    private
    def get_student_list
      @compcodes = session[:loggedUserCompCode]
      pages = params[:page].to_i > 0 ? params[:page] : 1
    
      # Reset session filters if server_request is present
      if params[:server_request].present?
        session[:req_student_list] = nil
        session[:req_course_search] = nil
        session[:req_year_search] = nil
      end
    
      # Extract filters or use session values
      course_search = params[:course_search].present? ? params[:course_search].strip : session[:req_course_search].to_s.strip
      filter_search = params[:student_list].present? ? params[:student_list].strip : session[:req_student_list].to_s.strip
      year_search = params[:year_search].present? ? params[:year_search].strip : session[:req_year_search].to_s.strip
    
      # Base condition
      iswhere = "mst_students.stdnt_compcode = '#{@compcodes}'"
    
      # Apply student list filter
      if filter_search.present?
        iswhere += " AND (stdnt_reg_no LIKE '%#{filter_search}%')"
        @student_list_search = filter_search
        session[:req_student_list] = filter_search
      end
    
      # Apply year filter
    if year_search.present?
      year_number = year_search.to_i

      # Calculate min/max semester for that year (2 sem per year)
      min_sem = (year_number - 1) * 2 + 1
      max_sem = year_number * 2

      iswhere += " AND gen_dtls.stdnt_gn_cur_sem BETWEEN #{min_sem} AND #{max_sem}"
      session[:req_year_search] = year_search
      @year_search = year_search
    end
    
      # Apply course filter
      if course_search.present?
        iswhere += " AND (stdnt_dtl_crse LIKE '%#{course_search}%')"
        session[:req_course_search] = course_search
        @course_search = course_search
      end
    
      # Define joins for the query
      joins = <<-SQL
        LEFT JOIN mst_student_dtls std 
          ON stdnt_dtl_compcode = stdnt_compcode AND stdnt_dtl_code = stdnt_reg_no
        LEFT JOIN mst_course_lists Mstd 
          ON stdnt_dtl_compcode = crse_compcode AND Mstd.id = stdnt_dtl_crse
        LEFT JOIN mst_stdnt_gen_dtls gen_dtls 
          ON mst_students.stdnt_compcode = gen_dtls.stdnt_gn_compcode AND mst_students.stdnt_reg_no = gen_dtls.stdnt_gn_code
      SQL
    
      # Add status filter
      iswhere += " AND (gen_dtls.stdnt_gn_status = 'A' OR gen_dtls.stdnt_gn_status = 'RE')"
    
      # Construct the query
      isselect = "mst_students.*, std.id as stdId, Mstd.id as mstId, gen_dtls.stdnt_gn_status"
    
      stdob = MstStudent.select(isselect).joins(joins).where(iswhere).order("stdnt_reg_no ASC")
    
      return stdob
    end
    

    private
    def save_student_details
      compcode                = session[:loggedUserCompCode]
      params[:stdnt_dtl_code] = stdnt_dtl_code = params[:stdnt_reg_no]
      message                 = ""
      isflags                 = false  
      certificatefile         = ""
      arrid                    = []
      pid = 0
      svuobj =  MstStudentDtl.where("stdnt_dtl_compcode = ? AND stdnt_dtl_code = ?",compcode,stdnt_dtl_code).first
       if svuobj
           certificatefile = svuobj.stdnt_dtl_pwdcertificate
           pid             = svuobj.id
           svuobj.update(process_student_details_params)    
           isflags= true
       else
          @svsobj = MstStudentDtl.new(process_student_details_params)
            if @svsobj.save 
              pid             = @svsobj.id.to_i     
              ### execute messa  
              chekfiles = MstStudentDtl.select("stdnt_dtl_pwdcertificate").where("stdnt_dtl_compcode = ? AND id = ?",compcode,pid).first           
              if chekfiles
                  certificatefile = chekfiles.stdnt_dtl_pwdcertificate
              end
              isflags = true
            end
       end
      return [pid,certificatefile]
      
    end

    private
    def student_params
      params[:stdnt_compcode] = session[:loggedUserCompCode]
      compcodes                        = session[:loggedUserCompCode]
      imgfolder  = "student"
      signs      = "studentsign"
      attachfile = ""
      signattach = ""
      currcategoryimage = params[:currcategoryimage]
      cursignature      = params[:cursignature]
      if params[:studentattach_file].present?   
        
          #   if params[:mid].to_i >0
          #         if currcategoryimage.to_s.present?
          #             storage_path = "#{compcodes}/student"
          #            bunny_delete_storage_file(currcategoryimage,storage_path)  
          #         end
          # end       
          
          attachfile = process_files_pos(params[:studentattach_file], params[:currcategoryimage], imgfolder)
            
      end
      if attachfile.to_s.blank?
          if currcategoryimage.to_s.present?
              attachfile = currcategoryimage
          end      
      end   
      if params[:stdnt_signature].present?        
          if params[:mid].to_i > 0          
                if cursignature.to_s.present?
                    signs_path = "#{compcodes}/studentsign"
                    bunny_delete_storage_file(cursignature,signs_path)                  
                end
          end         
       signattach = process_without_base64_files(params[:stdnt_signature], params[:cursignature], signs)   
    
    end
    if signattach.to_s.blank?
        if cursignature.to_s.present?
          signattach = cursignature
        end      
    end 
      params[:stdnt_signature] = signattach
      params[:stdnt_img]       = attachfile 
      params.permit(:stdnt_compcode,:stdnt_bloodgroup,:stdnt_signature,:stdnt_reg_no,:stdnt_reg_date,:stdnt_fname,:stdnt_lname,:stdnt_dob,:stdnt_gender,:stdnt_img)

    end

    private
    def process_student_details_params
        params[:stdnt_dtl_compcode]      = session[:loggedUserCompCode]
        compcodes                        = session[:loggedUserCompCode]
        attachfile          = "" 
        imgfolder           = "pwdcertificate"         
        curcertificate      = params[:curcertificate]
      if params[:stdnt_dtl_pwdcertificate].present?        
          if params[:mdid].to_i > 0
              if curcertificate.to_s.present?
                  storage_path = "#{compcodes}/#{imgfolder}"
                  bunny_delete_storage_file(curcertificate,storage_path)                       
              end
          end          
          attachfile = process_without_base64_files(params[:stdnt_dtl_pwdcertificate], params[:curcertificate], imgfolder)
            
      end
      if attachfile.to_s.blank?
          if curcertificate.to_s.present?
              attachfile = curcertificate
          end      
      end 

        params[:stdnt_dtl_pwdcertificate] = attachfile
        params.permit(:stdnt_dtl_compcode,:stdnt_dtl_typecourse,:stdnt_dtl_pwd,:stdnt_dtl_pwdcertificate,:stdnt_dtl_acctholder,:stdnt_dtl_code,:stdnt_dtl_crse,:stdnt_dtl_cat,:stdnt_dtl_add1,:stdnt_dtl_add2,:stdnt_dtl_city,:stdnt_dtl_nat,:stdnt_dtl_hstl,:stdnt_dtl_aadhaar,:stdnt_dtl_cont,:stdnt_dtl_email,:stdnt_dtl_bank,:stdnt_dtl_branch,:stdnt_dtl_acc,:stdnt_dtl_ifsc)
    end

    private
    def process_qualification(registraton)
       compcodes             = session[:loggedUserCompCode]
    #    cdir                  = "qualfattch"
       stdnt_fam_type          = params[:stdnt_fam_type] !=nil && params[:stdnt_fam_type]!='' ? params[:stdnt_fam_type] : ''
       stdnt_fam_father   = params[:stdnt_fam_father] !=nil && params[:stdnt_fam_father] !='' ? params[:stdnt_fam_father] : ''
       stdnt_fam_add1         = params[:stdnt_fam_add1] !=nil && params[:stdnt_fam_add1] !='' ? params[:stdnt_fam_add1] : ''
       stdnt_fam_add2       = params[:stdnt_fam_add2] !=nil && params[:stdnt_fam_add2] !='' ? params[:stdnt_fam_add2] : ''
       stdnt_fam_city          = params[:stdnt_fam_city] !=nil && params[:stdnt_fam_city] !='' ? params[:stdnt_fam_city] : ''
       stdnt_fam_tel_res        = params[:stdnt_fam_tel_res] !=nil && params[:stdnt_fam_tel_res] !='' ? params[:stdnt_fam_tel_res] : ''
       stdnt_fam_tel_off        = params[:stdnt_fam_tel_off] !=nil && params[:stdnt_fam_tel_off] !='' ? params[:stdnt_fam_tel_off] : ''
       stdnt_fam_email        = params[:stdnt_fam_email] !=nil && params[:stdnt_fam_email] !='' ? params[:stdnt_fam_email] : ''
       stdnt_fam_occu        = params[:stdnt_fam_occu] !=nil && params[:stdnt_fam_occu] !='' ? params[:stdnt_fam_occu] : ''
       stdnt_fam_income        = params[:stdnt_fam_income] !=nil && params[:stdnt_fam_income] !='' ? params[:stdnt_fam_income] : ''
    #    cur_qlf_attch         = params[:cur_qlf_attch] !=nil && params[:cur_qlf_attch] !='' ? params[:cur_qlf_attch] : ''
       footerid              = params[:qualiffooterid] !=nil && params[:qualiffooterid] !='' ? params[:qualiffooterid] : 0
       counts = 0;
        # if params[:skq_attach]!=nil && params[:skq_attach]!=''
        #      files      = params[:skq_attach]
        #      skq_attach = process_files(files,cur_qlf_attch,cdir)
        # else
        #      skq_attach = ''
        #  end
        #  if skq_attach == nil  || skq_attach == ''
        #     if cur_qlf_attch !=nil && cur_qlf_attch !=''
        #       skq_attach = cur_qlf_attch
        #     end
        #  end
         if stdnt_fam_type !=nil && stdnt_fam_type !=''
             process_save_qualification(compcodes,registraton,stdnt_fam_type,stdnt_fam_father,stdnt_fam_add1,stdnt_fam_add2,stdnt_fam_city,stdnt_fam_tel_res,stdnt_fam_tel_off,stdnt_fam_email,stdnt_fam_occu,stdnt_fam_income,footerid)
             counts = 1;
         end
         return counts;

  end

    private
    def process_save_qualification(stdnt_fam_compcode,stdnt_fam_code,stdnt_fam_type,stdnt_fam_father,stdnt_fam_add1,stdnt_fam_add2,stdnt_fam_city,stdnt_fam_tel_res,stdnt_fam_tel_off,stdnt_fam_email,stdnt_fam_occu,stdnt_fam_income,footerid)
        mstseuobj =   MstStdntFamily.where("stdnt_fam_compcode =? AND id = ?",stdnt_fam_compcode,footerid).first
        if mstseuobj
          mstseuobj.update(:stdnt_fam_code=>stdnt_fam_code,:stdnt_fam_type=>stdnt_fam_type,:stdnt_fam_father=>stdnt_fam_father,:stdnt_fam_add1=>stdnt_fam_add1,:stdnt_fam_add2=>stdnt_fam_add2,:stdnt_fam_city=>stdnt_fam_city,:stdnt_fam_tel_res=>stdnt_fam_tel_res,:stdnt_fam_tel_off=>stdnt_fam_tel_off,:stdnt_fam_email=>stdnt_fam_email,:stdnt_fam_occu=>stdnt_fam_occu,:stdnt_fam_income=>stdnt_fam_income)
            ## execute message if required
        else

            mstsvqlobj = MstStdntFamily.new(:stdnt_fam_compcode=>stdnt_fam_compcode,:stdnt_fam_code=>stdnt_fam_code,:stdnt_fam_type=>stdnt_fam_type,:stdnt_fam_father=>stdnt_fam_father,:stdnt_fam_add1=>stdnt_fam_add1,:stdnt_fam_add2=>stdnt_fam_add2,:stdnt_fam_city=>stdnt_fam_city,:stdnt_fam_tel_res=>stdnt_fam_tel_res,:stdnt_fam_tel_off=>stdnt_fam_tel_off,:stdnt_fam_email=>stdnt_fam_email,:stdnt_fam_occu=>stdnt_fam_occu,:stdnt_fam_income=>stdnt_fam_income)
            if mstsvqlobj.save
                ## execute message if required
            end
        end
    end

    
    
  


    private
    def process_general_params
      params[:stdnt_gn_compcode] = session[:loggedUserCompCode]
      compcodes                  = session[:loggedUserCompCode] 
      params[:stdnt_gn_status]      = 'A'
      params.permit(:stdnt_gn_compcode,:stdnt_gn_code,:stdnt_gn_nhmc,:stdnt_gn_opt_sub,:stdnt_gn_cur_sem,:stdnt_gn_admy,:stdnt_gn_jnu_ignou,:stdnt_gn_rank,:stdnt_gn_thry_grp,:stdnt_gn_status,:stdnt_gn_prac,:stdnt_gn_poy,:stdnt_gn_abc_id)
    end

    private
    def get_personal_information(compcode,empcode)
           sewdarobj =  MstStudentDtl.where("stdnt_dtl_compcode =? AND stdnt_dtl_code =?",compcode,empcode).first
           return sewdarobj
    end
  
    private
    def get_family_information(compcode,empcode)
           sewdarobj =  MstStdntFamily.where("stdnt_fam_compcode  =? AND stdnt_fam_code =?",compcode,empcode)
       return sewdarobj
    end

    private
    def get_course_student(compcode,crseid)
      sewdarobj =  MstCourseList.where("crse_compcode  =? AND id=?", compcode,crseid).first
      return sewdarobj
    end


    private
    def get_optional_subject(compcode,subid)
      sewdarobj =  MstSubjectList.where("sub_compcode  =? AND id=? ", compcode,subid).first
      return sewdarobj
    end


    private
    def get_general_information(compcode,registno)
       sewdarobj =  MstStdntGenDtl.where("stdnt_gn_compcode =? AND stdnt_gn_code =?",compcode,registno).first
       return sewdarobj
  end

  # private
  # def save_student_header
  #   compcodes = session[:loggedUserCompCode]
  #   @seriescode = ""
  #   # @profileimg = ""
  #   message     = ""
  #   mid         = ""
  #   isflags     = true
  #    ApplicationRecord.transaction do
  #   begin
  #  if params[:sw_sewadar_name] == nil  ||  params[:sw_sewadar_name] == ''
  #        message = "Registration No. is required."
  #        isflags = false

  #   elsif params[:sw_date_of_birth] == nil  ||  params[:sw_date_of_birth] == ''
  #        message = "Student name is required."
  #        isflags = false
  #   else
  #           # sewdcat       =  params[:sw_catgeory] !=nil && params[:sw_catgeory] !='' ?  params[:sw_catgeory].to_s.split("-") : ''
  #           # seadarcatcode =  sewdcat[0] ? sewdcat[0].to_s.strip : ''
  #           registratno    =  params[:stdnt_reg_no] !=nil && params[:stdnt_reg_no] !='' ?  params[:stdnt_reg_no].to_s.strip : ''
  #           sewdobj       =  MstStudent.where("stdnt_compcode = ? AND stdnt_reg_no = ?",compcodes,registratno).first
  #           if sewdobj
  #               sewdobj.update(sewadar_params)
  #                message = "Data updated successfully."
  #                isflags = true
  #                mid     = sewdobj.id
  #           else
  #             sewsvobj = MstStudent.new(sewadar_params)
  #              if sewsvobj.save
  #                 mid = sewsvobj.id
  #                message = "Data saved successfully."
  #                 isflags = true
  #              end
  #           end
  #   end
  #         rescue Exception => exc
  #               message   = "#{exc.message}"
  #               isflags   = false
  #               raise ActiveRecord::Rollback
  #         end
  #   end
  #   respond_to do |format|
  #     format.json { render :json => { 'data'=>mid, "message"=>message,:status=>isflags} }
  #   end
  # end

  private
  def save_parent_details
        compcodes = session[:loggedUserCompCode]
        registno  = params[:stdnt_reg_no]
        qltype    = params[:stdnt_fam_type]
        footerid  = params[:qualiffooterid] !=nil && params[:qualiffooterid] !='' ? params[:qualiffooterid] : 0
        isFlags   = true
        message   = ""
        if params[:stdnt_reg_no].to_s.blank?
            message = "Registration number is required."
            isFlags   = false
        elsif params[:stdnt_fam_type].to_s.blank?
          message = "Info type is required."
          isFlags   = false
        elsif params[:stdnt_fam_father].to_s.blank?
          message = "Name is required."
          isFlags   = false  
        elsif params[:stdnt_fam_add1].to_s.blank?
          message = "Address 1 is required."
          isFlags   = false
       #  elsif params[:stdnt_fam_occu].to_s.blank?
         # message = "Occupation is required."
         # isFlags   = false
       # elsif params[:stdnt_fam_income].to_s.blank?
        #  message = "Income is required."
         # isFlags   = false
         end
         if isFlags
                if  qltype != nil && qltype !=''
                      procescount =  process_qualification(registno)
                      if procescount.to_i >0
                        isFlags = true
                        if footerid.to_i >0
                          message = "Data updated sucessfully"
                        else
                          message = "Data saved sucessfully"
                        end
          
                      else
                        message = "Data could not be processed due to technical issue."
                      end
                end
        end     
      studentadmfam = get_all_family_information(compcodes,registno)
      vhtml   = render_to_string :template  => 'student_list/view_student_admission_list',:layout => false, :locals => { :mydata => studentadmfam}
      respond_to do |format|
        format.json { render :json => { 'data'=>vhtml,"message"=>message,:status=>isFlags} }
      end
  end

  private
  def save_general_details
    compcode               = session[:loggedUserCompCode]
    params[:stdnt_gn_code] = stdnt_gn_code = params[:stdnt_reg_no]
    message                = ""
    isflags                = true
    ApplicationRecord.transaction do
     begin
    svuobj =  MstStdntGenDtl.where("stdnt_gn_compcode = ? AND stdnt_gn_code = ?",compcode,stdnt_gn_code).first
     if svuobj
       svuobj.update(process_general_params)     
       message = "Data updated successfully."
       isflags = true
     else
       svsobj = MstStdntGenDtl.new(process_general_params)
        if svsobj.save        
          ### execute message
           message = "Data saved successfully."
           isflags = true
        end
     end
     rescue Exception => exc
            message   = "#{exc.message}"
            isflags   = false
            raise ActiveRecord::Rollback
          end
    end
     respond_to do |format|
      format.json { render :json => { 'data'=>'', "message"=>message,:status=>isflags} }
    end

  end

  private
  def print_student_list
    @compcodes      = session[:loggedUserCompCode] 
    course_search = session[:req_course_search].to_s.strip       
    filter_search = session[:req_student_list].to_s.strip       
    iswhere       = "stdnt_compcode ='#{@compcodes}'"        
    if filter_search !=nil && filter_search !=''
      iswhere +=" AND ( stdnt_reg_no LIKE '%#{filter_search}%' )"
    end    
    if course_search !=nil && course_search !=''
      iswhere +=" AND ( stdnt_dtl_crse LIKE '%#{course_search}%' )"
    end
      isselect = "mst_students.*,std.id as stdId, stdnt_dtl_crse, std.stdnt_dtl_cont, std.stdnt_dtl_email,'' as crse_code,'' as nhmcno"
      jons  = "LEFT JOIN mst_student_dtls std ON( stdnt_dtl_compcode = stdnt_compcode AND stdnt_dtl_code = stdnt_reg_no)"
      studentobj =  MstStudent.select(isselect).joins(jons).where(iswhere).order("stdnt_reg_no ASC")
      arritem  = []
  
      if studentobj.length >0
        studentobj.each do |newitesm|
          courseobj =  get_course_detail(newitesm.stdnt_dtl_crse)
          if courseobj   
            newitesm.crse_code = courseobj.crse_code
          end
          nhmcobj = get_general_information(newitesm.stdnt_compcode,newitesm.stdnt_reg_no)
          if nhmcobj
            newitesm.nhmcno = nhmcobj.stdnt_gn_nhmc
          end
          arritem.push newitesm
        end
    return studentobj
  end
end

end