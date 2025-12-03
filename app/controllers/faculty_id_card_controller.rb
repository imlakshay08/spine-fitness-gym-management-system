class FacultyIdCardController < ApplicationController
     before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token

  def index
       @compcodes        = session[:loggedUserCompCode] 
        @printPath    =  "faculty_id_card/1_prt_faculty_id_card.pdf"
       
  end

  def show
    @compcodes     = session[:loggedUserCompCode]
    @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
     rooturl       = "#{root_url}"
     if params[:id] != nil && params[:id] != ''
       docsid  = params[:id].to_s.split("_")
 
       if  docsid[2] == 'faculty'
         types         = session[:my_sl_type]
         @reportdata = print_faculty_id_card()
         if types == 'ID'
            respond_to do |format|
                      format.pdf do
                       pdf = FacultyidcardPdf.new(@reportdata, @compDetail, rooturl)
                       send_data pdf.render,:filename => "1_prt_faculty_id_card.pdf", :type => "application/pdf", :disposition => "inline"
                    end
             end
    
         end
    
    end
 end
 
 end


  def ajax_process
      if params[:identity]!=nil && params[:identity]!='' && params[:identity] == 'Y'
        get_faculty_info()
        return  
     end
  
    
  end
  private

  
       private
       def get_faculty_info
        @compcodes     = session[:loggedUserCompCode]
        session[:course_code]       = nil
        session[:faculty_code]      = nil
        session[:faculty_code_upto] = nil
        session[:my_sl_type]        = nil
         
         serverreq          = params[:server_request] !=nil && params[:server_request]  !='' ? params[:server_request] : session[:rqs_server_request]
        
         faculty_code       = params[:faculty_code] !=nil && params[:faculty_code] !='' ? params[:faculty_code] : session[:faculty_code]
         faculty_code_upto  = params[:faculty_code_upto] !=nil && params[:faculty_code_upto] !='' ? params[:faculty_code_upto] : session[:faculty_code_upto]
         sltype             = params[:sltype] !=nil && params[:sltype] != '' ? params[:sltype] : session[:my_sl_type]
         
         iswhere    = "fclty_compcode ='#{@compcodes}'";
         
          if faculty_code.present?
            iswhere += " AND fclty_code >= '#{faculty_code}'"
            @faculty_code =  faculty_code
            myflags = true
            session[:faculty_code] = faculty_code
         end
         if faculty_code_upto.present?
           iswhere += " AND fclty_code <= '#{faculty_code_upto}'"
           @faculty_code_upto =  faculty_code_upto
           myflags = true
           session[:faculty_code_upto] = faculty_code_upto
        end
      
  
       if sltype !=nil && sltype !='' && sltype =='ID'
         session[:my_sl_type]  = sltype
       
     end
         
         isflags   = false
         message   = ""
         studentobj = MstFaculty.where(iswhere).order("id DESC")
         if studentobj.length >0
           isflags = true
           message ="Success"
         end
         respond_to do |format|
           format.json { render :json => { 'data'=>'', "message"=>message,:status=>isflags} }
         end
       end
  


  
  private
  def print_faculty_id_card()
    @compcodes     = session[:loggedUserCompCode]
     myflags           = false
    serverreq          = session[:rqs_server_request]
    faculty_code      = session[:faculty_code] 
    faculty_code_upto  = session[:faculty_code_upto]
    sltype             = session[:my_sl_type]
       
    iswhere    = "fclty_compcode ='#{@compcodes}'";

    
          if faculty_code.present?
             iswhere += " AND fclty_code >= '#{faculty_code}'"
             myflags     = true   
          end
          if faculty_code_upto.present?
            iswhere += " AND fclty_code <= '#{faculty_code_upto}'"
            myflags     = true   
         end
        
      
    if sltype !=nil && sltype !='' && sltype =='ID'
      session[:my_sl_type]  = sltype
  end
  
    facultyobj = MstFaculty.where(iswhere).order("id DESC")
  
    return facultyobj
end

end
