class StudentTransactionListController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
   
    def index
        @compcodes      = session[:loggedUserCompCode]
        @student_transaction     = get_student_transaction()
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first

        printPath     =  "student_transaction_list/1_prt_student_transaction_list.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt'
              
              @transactiondetail   = print_student_transaction_list()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = TransactionPdf.new(@transactiondetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_student_transaction_list.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def add_student_transaction
        @compcodes      = session[:loggedUserCompCode]
        @Liststdnttrnsctn = nil
        @Lastcode=generate_regularization_series
        if params[:id].to_i>0
            @Liststdnttrnsctn= TrnStudentList.where("trn_compcode=? AND id=?",@compcodes,params[:id]).first
         end
    end

    def ajax_process
        @compcodes      = session[:loggedUserCompCode] 
        if params[:identity]!=nil && params[:identity]!= '' && params[:identity] == 'STUDENTDTLS'
            search_student_detail_listed()
            return
        elsif params[:identity]!=nil && params[:identity]!= '' && params[:identity] == 'STUDENT'
            get_student_details()
            return
        elsif params[:identity]!=nil && params[:identity]!= '' && params[:identity] == 'STUDENTGENDTL'
          search_student_gen_detail()
            return
        end
    end

    def create
        @compcodes      = session[:loggedUserCompCode] 
        isFlags     = true
        mid         = params[:mid]
        studentcode = params[:trn_stdnt_rollno]
        type = params[:trn_type]
        cancel=params[:trn_cancel]
        current_status=params[:trn_cur_status]
        begin
            if params[:trn_no].to_s.blank?
               flash[:error] =  "Transaction No. is Required"
               isFlags = false
            elsif
               params[:trn_date].to_s.blank?
               flash[:error] =  "Date is Required"
               isFlags = false
            elsif
              params[:trn_stdnt_rollno].to_s.blank?
              flash[:error] =  "Student Rollno is Required"
              isFlags = false
            elsif
               params[:trn_stdnt_name].to_s.blank?
               flash[:error] =  "Student Name is Required"
               isFlags = false
              elsif
                params[:trn_type].to_s.blank?
                flash[:error] =  "Transaction Type is Required"
                isFlags = false
            elsif
                params[:trn_year].to_s.blank?
                flash[:error] =  "Year is Required"
                isFlags = false
            end
  
              currentgrp =  params[:cur_trn_stdnt_rollno].to_s.strip
              newgroup   =  params[:trn_stdnt_rollno].to_s.strip
              year       =   params[:trn_year].to_s.strip
            curyear     =    params[:cur_trn_year].to_s.strip

                if params[:mid].to_i>0
                   if currentgrp.to_s.downcase != newgroup.to_s.downcase
                    if curyear.to_s.downcase != year.to_s.downcase
                       chkgrpobj   = TrnStudentList.where("trn_compcode=? AND LOWER(trn_stdnt_rollno)=? AND LOWER(trn_year)=? AND trn_cancel != 'C' ",@compcodes,newgroup.to_s.downcase,year.to_s.downcase)
                       if chkgrpobj.length>0
                           flash[:error] = "This Transaction is already performed on this student for this year!"
                           isFlags        = false
                       end
                      end
                   
                  end
           
                 if isFlags
                       chkgrpobj   = TrnStudentList.where("trn_compcode=? AND id=?",@compcodes,mid).first
                       if chkgrpobj
                           chkgrpobj.update(transaction_params)
                           flash[:error] = "Data updated successfully"
                           isFlags       = true
                           modulename = "Student Transaction List"
                           description = "Student Transaction List List Update: #{params[:trn_stdnt_rollno]}"
                           process_request_log_data("UPDATE", modulename, description)
                       end
                 end
               else
            
                   chkgrpobj   = TrnStudentList.where("trn_compcode=? AND LOWER(trn_stdnt_rollno)=? AND LOWER(trn_year)=? AND trn_cancel != 'C'",@compcodes,newgroup.to_s.downcase,year.to_s.downcase)
                   if chkgrpobj.length>0
                     flash[:error] = "This Transaction is already performed on this student for this year!"
                    isFlags        = false
                   
                   end
                     if isFlags
                         savegrp = TrnStudentList.new(transaction_params)
                         if savegrp.save
                             update_student_status(studentcode,type)
                            #  previous_status=current_status
                            #  savegrp.update(trn_cur_status: type)
                             flash[:error] = "Data saved successfully"
                             isFlags       = true
                             modulename = "Student Transaction List List"
                             description = "Student Transaction List List Save: #{params[:trn_stdnt_rollno]}"
                             process_request_log_data("SAVE", modulename, description)
                        
                         end
                     end
                  
               end
               if !isFlags
                   session[:isErrorhandled] = 1
                   session[:postedpamams]   = nil
                  #  session[:sess_fclty_img] = params[:fclty_img]
                   session[:sess_trn_no] = params[:trn_no]
                   session[:sess_trn_date] = params[:trn_date]
                   session[:sess_trn_stdnt_rollno] = params[:trn_stdnt_rollno]
                   session[:sess_trn_stdnt_name] = params[:trn_stdnt_name]
                   session[:sess_trn_year] = params[:trn_year]
                   session[:sess_trn_type] = params[:trn_type]
                   session[:sess_trn_cur_status] = params[:trn_cur_status]
                  #  session[:sess_trn_prev_status] = params[:trn_prev_status]

               else
                   session[:isErrorhandled] = nil
                   session[:postedpamams]   = nil
                   session[:sess_trn_no] = nil
                   session[:sess_trn_date] = nil
                   session[:sess_trn_stdnt_rollno] = nil
                   session[:sess_trn_stdnt_name] = nil
                   session[:sess_trn_year] = nil
                   session[:sess_trn_type] = nil
                   session[:sess_trn_cur_status] =nil
  
                   isFlags = true
               end
               rescue Exception => exc
                   flash[:error] =  "ERROR: #{exc.message}"
                   session[:isErrorhandled] = 1
                   isFlags = false
               end
  
              # chkgrpobj   = MstFaculty.where("fclty_compcode=? ",@compcodes)
              # respond_to do |format|
              #   format.json { render :json => { 'data'=>chkgrpobj,:status=>isFlags,:message=>message} }
              # end
  
               if isFlags
                   redirect_to  "#{root_url}student_transaction_list"
               else
                   if params[:mid].to_i>0 
                       redirect_to  "#{root_url}student_transaction_list/add_student_transaction/"+params[:mid].to_s
                   else
                       redirect_to  "#{root_url}student_transaction_list/add_student_transaction"
                   end
                     
               end
      end

    def referesh_student_transaction_list
      session[:req_rollno_search] = nil
      session[:req_transaction_search] = nil
      session[:req_year_searhc] = nil
      redirect_to "#{root_url}student_transaction_list"
    end

    def destroy
      compcodes = session[:loggedUserCompCode]
      trn_cur_status = params[:trn_cur_status]
      studentcode = ''
      
      if params[:id].to_i > 0
        canobj = TrnStudentList.where("trn_compcode = ? AND id = ?", compcodes, params[:id].to_i).first
        trn_cur_status = canobj.trn_cur_status # Get the current status from the transaction record

        if canobj
          studentcode = canobj.trn_stdnt_rollno
          checkobj = MstStdntGenDtl.where("stdnt_gn_compcode = ? AND stdnt_gn_code = ?", compcodes, studentcode).first
          
          if checkobj
            canobj.update( trn_cancel: 'C')
            checkobj.update(stdnt_gn_status: trn_cur_status)
            flash[:error] = "Data cancelled successfully."
          else
            flash[:error] = "Student record not found."
          end
        else
          flash[:error] = "Transaction record not found."
        end
      end
      
      redirect_to "#{root_url}student_transaction_list"
    end
    

    def update_student_status(studentcode, type)
      compcodes = session[:loggedUserCompCode]
      checkobj = MstStdntGenDtl.where("stdnt_gn_compcode =? AND stdnt_gn_code =?", compcodes, studentcode).first
      
      if checkobj
        checkobj.update(stdnt_gn_status: type)
      end
    end
    
 

    private
    def transaction_params
        params[:trn_compcode]     = session[:loggedUserCompCode] 
        if params[:trn_cur_status].blank?
          params[:trn_cur_status]      = 'A'
          end
        params.permit(:trn_compcode,:trn_no,:trn_date,:trn_stdnt_rollno,:trn_stdnt_name,:trn_year,:trn_type,:trn_cur_status,:trn_cancel)
    end

    private
    def generate_regularization_series
        @compcodes      = session[:loggedUserCompCode]
         @isCode     = 0
         @Startx     = '0000' 
         @recCodes  = TrnStudentList.where(["trn_compcode = ? AND trn_no <>'' ", @compcodes]).order('trn_no DESC').first
         if @recCodes
           @isCode    = @recCodes.trn_no.to_i
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

    private
    def search_student_gen_detail
      compcodes   = session[:loggedUserCompCode]
      requesttype = params[:requesttype]
      trn_cur_status = params[:trn_cur_status]
      trn_stdnt_rollno = params[:trn_stdnt_rollno]
      semester = params[:semester]
      depcode     = params[:depcode]
      sewdobj     = nil
      isFlags     = false
      isselect   = "stdnt_gn_status as employeename, stdnt_gn_code as employeecode, stdnt_gn_cur_sem as semester"
      if requesttype.to_s == 'CODE'
            iswhere    = "stdnt_gn_compcode='#{compcodes}' AND UPPER(stdnt_gn_code)=UPPER('#{trn_stdnt_rollno}') "
             
            sewdobj    = MstStdntGenDtl.select(isselect).where(iswhere).first
              if sewdobj.present?
                semester = sewdobj.semester
                isFlags = true
            end
              
      else
        iswhere = "stdnt_gn_compcode='#{compcodes}' AND stdnt_gn_status LIKE '%#{trn_cur_status}%' OR stdnt_gn_cur_sem='#{semester}'"
             
             sewdobj    = MstStdntGenDtl.select(isselect).where(iswhere).order("stdnt_gn_status ASC")
             if sewdobj.length>0
                isFlags = true
             end
      end
          respond_to do |format|
            format.json { render :json => { 'data'=>sewdobj,'semester'=>semester,:status=>isFlags} }
          end
    end

    private
    def print_student_transaction_list
      @compcodes      = session[:loggedUserCompCode] 
      iswhere         = "trn_compcode ='#{@compcodes}' AND trn_cancel != 'C'"
      rollno_search   = session[:req_rollno_search]
      year_searhc     =  session[:req_year_searhc]
      transaction_search  =  session[:req_transaction_search]
   
      if rollno_search !=nil && rollno_search !=''
          iswhere +=" AND ( trn_stdnt_rollno LIKE '%#{filter_search}%')"
      end  
      if transaction_search !=nil && transaction_search !=''
          iswhere +=" AND ( trn_type LIKE '%#{transaction_search}%' )"
      end
      if year_searhc !=nil && year_searhc !=''
        iswhere +=" AND ( trn_year LIKE '%#{year_searhc}%' )"
      end 
      stdob =  TrnStudentList.where(iswhere).order("trn_stdnt_rollno ASC")
      return stdob
  end

    private
    def search_student_detail_listed
        compcodes   = session[:loggedUserCompCode]
        requesttype = params[:requesttype]
        trn_stdnt_name = params[:trn_stdnt_name]
        trn_stdnt_rollno = params[:trn_stdnt_rollno]
        depcode     = params[:depcode]
        sewdobj     = nil
        isFlags     = false
        isselect   = "CONCAT(stdnt_fname, ' ', stdnt_lname) as employeename, stdnt_reg_no as employeecode"
        if requesttype.to_s == 'CODE'
              iswhere    = "stdnt_compcode='#{compcodes}' AND UPPER(stdnt_reg_no)=UPPER('#{trn_stdnt_rollno}') "
               
              sewdobj    = MstStudent.select(isselect).where(iswhere).first
              if sewdobj
                isFlags = true
              end
        else
          iswhere = "stdnt_compcode='#{compcodes}' AND (stdnt_fname LIKE '%#{trn_stdnt_name}%' OR stdnt_lname LIKE '%#{trn_stdnt_name}%')"
               
               sewdobj    = MstStudent.select(isselect).where(iswhere).order("stdnt_fname ASC")
               if sewdobj.length>0
                  isFlags = true
               end
        end
            respond_to do |format|
              format.json { render :json => { 'data'=>sewdobj,:status=>isFlags} }
            end
    end

    private
    def get_student_transaction
        @compcodes      = session[:loggedUserCompCode] 
        if params[:page].to_i >0
           pages = params[:page]
        else
           pages = 1
        end

        if params[:server_request]!=nil && params[:server_request]!= ''           
          session[:req_rollno_search] = nil
          session[:req_transaction_search] = nil
          session[:req_year_searhc] = nil
       end
       transaction_search = params[:transaction_search] !=nil && params[:transaction_search] != '' ? params[:transaction_search].to_s.strip : session[:req_transaction_search].to_s.strip       
       rollno_search = params[:rollno_search] !=nil && params[:rollno_search] != '' ? params[:rollno_search].to_s.strip : session[:req_rollno_search].to_s.strip       
       year_searhc  = params[:year_searhc] !=nil && params[:year_searhc] != '' ? params[:year_searhc].to_s.strip : session[:req_year_searhc].to_s.strip
       iswhere       = "trn_compcode ='#{@compcodes}'"        
       if rollno_search !=nil && rollno_search !=''
          iswhere +=" AND ( trn_stdnt_rollno LIKE '%#{rollno_search}%' )"
          @rollno_search       = rollno_search
          session[:req_rollno_search] = rollno_search
       end    
       if transaction_search !=nil && transaction_search !=''
           iswhere +=" AND ( trn_type LIKE '%#{transaction_search}%' )"
           session[:req_transaction_search] = transaction_search
           @transaction_search              = transaction_search
       end
       if year_searhc !=nil && year_searhc !=''
        iswhere +=" AND ( trn_year LIKE '%#{year_searhc}%' )"
        session[:req_year_searhc] = year_searhc
        @year_searhc              = year_searhc
    end

        stdob =  TrnStudentList.where(iswhere).order("trn_no ASC")
     return stdob
        
    end

    private
    def get_student_details
        compcodes   = session[:loggedUserCompCode] 
        requesttype = params[:requesttype]
        studentcode = params[:studentcode]
        course      = nil
        isFlags     = false
    
        isselect   = "id, stdnt_dtl_code as studentcode, stdnt_dtl_crse as course"
        if requesttype.to_s == 'CODE'
            iswhere    = "stdnt_dtl_compcode='#{compcodes}' AND stdnt_dtl_code ='#{studentcode}'"
            sewdobj    = MstStudentDtl.select(isselect).where(iswhere).first
    
            if sewdobj.present?
                course = sewdobj.course
                courses = get_course_detail(course) unless course.nil?
                isFlags = true
            end
        else
            iswhere    = "stdnt_dtl_compcode='#{compcodes}' AND stdnt_dtl_code LIKE '%#{studentcode}%'"
            iswhere += " AND UPPER(stdnt_dtl_crse)=UPPER('#{course}')" if course.present?
    
            sewdobj    = MstStudentDtl.select(isselect).where(iswhere).order("stdnt_dtl_code ASC")
            if sewdobj.any?
                isFlags = true
                courses = sewdobj.map { |newloc| get_course_detail(newloc.course) }
            end
        end
    
        respond_to do |format|
            format.json { render json: { 'data' => sewdobj, 'course' => courses, status: isFlags } }
        end
    end
    
end
