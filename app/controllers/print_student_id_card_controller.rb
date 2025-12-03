class PrintStudentIdCardController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token

  def index
       @compcodes        = session[:loggedUserCompCode] 
        @printPath    =  "print_student_id_card/1_prt_student_id_card.pdf"
        @CourseList   = MstCourseList.where("crse_compcode =? AND crse_code != ''  ",@compcodes)
  end

  def show
    @compcodes     = session[:loggedUserCompCode]
    @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
     rooturl       = "#{root_url}"
     if params[:id] != nil && params[:id] != ''
       docsid  = params[:id].to_s.split("_")
 
       if  docsid[2] == 'student'
         types         = session[:my_sl_type]
         @reportdata = print_student_id_card()
         if types == 'ID'
            respond_to do |format|
                      format.pdf do
                       pdf = StudentidcardPdf.new(@reportdata, @compDetail, rooturl)
                       send_data pdf.render,:filename => "1_prt_student_id_card.pdf", :type => "application/pdf", :disposition => "inline"
                    end
             end
    
         end
    
    end
 end
 
 end


  def ajax_process
      if params[:identity]!=nil && params[:identity]!='' && params[:identity] == 'Y'
        get_student_info()
        return  
     end
  
    
  end
  private

  
       private
       def get_student_info
        @compcodes     = session[:loggedUserCompCode]
        session[:course_code]     = nil
        session[:stdnt_roll_no]   = nil
        session[:roll_no_upto]    = nil
        session[:my_sl_type]      = nil
         
         serverreq          = params[:server_request] !=nil && params[:server_request]  !='' ? params[:server_request] : session[:rqs_server_request]
         course_code        = params[:course_code] !=nil && params[:course_code] !='' ? params[:course_code] : session[:course_code]
         stdnt_roll_no      = params[:stdnt_roll_no] !=nil && params[:stdnt_roll_no] !='' ? params[:stdnt_roll_no] : session[:stdnt_roll_no]
         roll_no_upto       = params[:roll_no_upto] !=nil && params[:roll_no_upto] !='' ? params[:roll_no_upto] : session[:roll_no_upto]
         sltype             = params[:sltype] !=nil && params[:sltype] != '' ? params[:sltype] : session[:my_sl_type]
         
         iswhere    = "stdnt_compcode ='#{@compcodes}'";
          if course_code !=nil && course_code !=''
               iswhere += " AND stdnt_dtl_crse='#{course_code}' ";
               @course_code =  course_code
                myflags     = true
                session[:course_code] = course_code
                
          end
          if stdnt_roll_no.present?
            iswhere += " AND stdnt_reg_no >= '#{stdnt_roll_no}'"
            @stdnt_roll_no =  stdnt_roll_no
            myflags = true
            session[:stdnt_roll_no] = stdnt_roll_no
         end
         if roll_no_upto.present?
           iswhere += " AND stdnt_reg_no <= '#{roll_no_upto}'"
           @roll_no_upto =  roll_no_upto
           myflags = true
           session[:roll_no_upto] = roll_no_upto
        end
      
  
       if sltype !=nil && sltype !='' && sltype =='ID'
         session[:my_sl_type]  = sltype
       
     end
         
         isflags   = false
         message   = ""
         isselect   = "mst_students.*,stdnt_dtl_crse"
         jons       = " JOIN mst_student_dtls stdtl ON(stdnt_reg_no = stdnt_dtl_code )"
         studentobj = MstStudent.joins(jons).where(iswhere).order("id DESC")
         if studentobj.length >0
           isflags = true
           message ="Success"
         end
         respond_to do |format|
           format.json { render :json => { 'data'=>'', "message"=>message,:status=>isflags} }
         end
       end
  


  
  private
  def print_student_id_card()
    @compcodes     = session[:loggedUserCompCode]
     myflags           = false
    serverreq          = session[:rqs_server_request]
    course_code        = session[:course_code]
    stdnt_roll_no      = session[:stdnt_roll_no] # Capture the "From" roll number from the form
    roll_no_upto       = session[:roll_no_upto] # Capture the "Upto" roll number from the form
    sltype             = session[:my_sl_type]
       
    iswhere    = "stdnt_compcode ='#{@compcodes}'";

       if course_code !=nil && course_code !=''
               iswhere += " AND stdnt_dtl_crse='#{course_code}' ";
                myflags     = true     
          end
          if stdnt_roll_no.present?
             iswhere += " AND stdnt_reg_no >= '#{stdnt_roll_no}'"
             myflags     = true   
          end
          if roll_no_upto.present?
            iswhere += " AND stdnt_reg_no <= '#{roll_no_upto}'"
            myflags     = true   
         end
        
      
    if sltype !=nil && sltype !='' && sltype =='ID'
      session[:my_sl_type]  = sltype
  end
     isselect   = "mst_students.*, stdnt_dtl_crse, stdnt_dtl_cont, stdnt_dtl_add1, stdnt_dtl_add2,'' as coursecode,'' as fathername,''as courseduration,''as registyear"
    jons       = " JOIN mst_student_dtls stdtl ON( stdnt_dtl_code = stdnt_reg_no )"
    studentobj = MstStudent.joins(jons).select(isselect).where(iswhere).order("id DESC")
    arritem  = []
  
    if studentobj.length >0
      studentobj.each do |newitesm|
        newitesm.registyear = newitesm.stdnt_reg_date.year
        courseobj =  get_course_detail(newitesm.stdnt_dtl_crse)
        if courseobj   
          newitesm.coursecode = courseobj.crse_code

          duration_in_years = courseobj.crse_duration.match(/\d+/)[0].to_i # This extracts the number and converts it to an integer
          completion_year = newitesm.registyear + duration_in_years

          newitesm.courseduration = newitesm.registyear + duration_in_years
        end
        fatherobj  = get_father_information(newitesm.stdnt_reg_no)
        if fatherobj
          newitesm.fathername = fatherobj.stdnt_fam_father
        end
      arritem.push newitesm
      end
    return studentobj
    end
end 

private
def get_father_information(studentcode)
       @compcodes     = session[:loggedUserCompCode]
       sewdarobj =  MstStdntFamily.where("stdnt_fam_compcode  =? AND stdnt_fam_code =? AND stdnt_fam_type = 'Father'",@compcodes,studentcode).first
   return sewdarobj
end

end
