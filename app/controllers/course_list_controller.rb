class CourseListController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    helper_method :check_existing_uses_subject, :check_existing_uses_student
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        @course_list = get_course_list()
        printPath     =  "course_list/1_prt_course_list.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'course'
              
              @coursedetail   = print_course_list()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = CoursePdf.new(@coursedetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_course_list.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def add_course
        @compcodes      = session[:loggedUserCompCode] 
        @course = nil
        if params[:id].to_i>0
            @course= MstCourseList.where("crse_compcode=? AND id=?",@compcodes,params[:id]).first
         end
    end

    def referesh_course_list
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        session[:req_course_list] = nil
        isFlags = true
        redirect_to  "#{root_url}course_list"
    end

    def create
        @compcodes      = session[:loggedUserCompCode] 
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:crse_code].to_s.blank?
           flash[:error] =  "Course Code is Required"
           isFlags = false
        end
        if params[:crse_descp].to_s.blank?
          flash[:error] =  "Course Description is Required"
          isFlags = false
       end
       if params[:crse_duration].to_s.blank?
        flash[:error] =  "Course Duration is Required"
        isFlags = false
     end
     if params[:crse_term].to_s.blank?
        flash[:error] =  "Course Term is Required"
        isFlags = false
     end
     if params[:crse_seats].to_s.blank?
        flash[:error] =  "Course Seats is Required"
        isFlags = false
     end
        currentgrp =  params[:cur_course_code].to_s.strip
        newgroup   =  params[:crse_code].to_s.strip
        duration   =  params[:crse_duration].to_s.strip
        term   =  params[:crse_term].to_s.strip
        seat   =  params[:crse_seats].to_s.strip
    
        if params[:mid].to_i>0
            if currentgrp.to_s.downcase != newgroup.to_s.downcase
                chkgrpobj   = MstCourseList.where("crse_compcode=? AND LOWER(crse_code)=? ",@compcodes,newgroup.to_s.downcase)
                if chkgrpobj.length>0
                    flash[:error] = "Could not be create duplicate Course."
                    isFlags        = false
                end
            end
    
          if isFlags
                chkgrpobj   = MstCourseList.where("crse_compcode=? AND id=?",@compcodes,mid).first
                if chkgrpobj
                    chkgrpobj.update(course_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                    modulename = "Course List"
                    description = "Course List Update: #{params[:crse_code]}"
                    process_request_log_data("UPDATE", modulename, description)
                
                end
          end
        else
            chkgrpobj   = MstCourseList.where("crse_compcode=? AND LOWER(crse_code)=?",@compcodes,newgroup.to_s.downcase)
            if chkgrpobj.length>0
              flash[:error] = "Could not be create duplicate Course."
             isFlags        = false
            end
              if isFlags
                  savegrp = MstCourseList.new(course_params)
                  if savegrp.save
                      flash[:error] = "Data saved successfully"
                      isFlags       = true
                      modulename = "Course List"
                    description = "Course List Save: #{params[:crse_code]}"
                    process_request_log_data("SAVE", modulename, description)
                
                  end
              end
    
        end
        if !isFlags
            session[:isErrorhandled] = 1
            session[:postedpamams]   = params
        else
            session[:isErrorhandled] = nil
            session[:postedpamams]   = nil
            isFlags = true
        end
        rescue Exception => exc
            flash[:error] =  "ERROR: #{exc.message}"
            session[:isErrorhandled] = 1
            isFlags = false
        end
        if isFlags
            redirect_to  "#{root_url}course_list"
        else
            if params[:mid].to_i>0 
                redirect_to  "#{root_url}course_list/add_course/"+params[:mid].to_s
            else
                redirect_to  "#{root_url}course_list/add_course"
            end
              
        end
    
    end

    def destroy
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i >0
           @ListSate =  MstCourseList.where("crse_compcode=? AND id=?", @compcodes,params[:id].to_i).first
            if @ListSate
                chekobj =  check_existing_uses_subject(@ListSate.id)
                if chekobj                   
                    flash[:error] =  "Sorry !! The Selected course could not be deleted as it is being used in Subject List."
                    isFlags       =  true
                    session[:isErrorhandled] = 1
                else @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
               chekob =  check_existing_uses_student(@ListSate.id)
                if chekob                   
                    flash[:error] =  "Sorry !! The Selected course could not be deleted as it is being used in Student List."
                    isFlags       =  true
                    session[:isErrorhandled] = 1
                else @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
            end
       end
       redirect_to "#{root_url}course_list"
    end

    private
    def get_course_list
        @compcodes      = session[:loggedUserCompCode] 
        if params[:page].to_i >0
            pages = params[:page]
            else
            pages = 1
            end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
            #  session[:req_course_list] = nil
          # end
          filter_search = params[:course_list] !=nil && params[:course_list] != '' ? params[:course_list].to_s.strip : session[:req_course_list].to_s.strip       
          iswhere       = "crse_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( crse_code LIKE '%#{filter_search}%' OR crse_descp LIKE '%#{filter_search}%')"
            @course_list_search       = filter_search
            session[:req_course_list] = filter_search
          end     
        
          stdob =  MstCourseList.where(iswhere).order("crse_code ASC")
          return stdob

    end

    def print_course_list
        @compcodes      = session[:loggedUserCompCode] 
        iswhere         = "crse_compcode ='#{@compcodes}'"
        filter_search   = session[:req_course_list]   
        if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( crse_code LIKE '%#{filter_search}%' OR crse_descp LIKE '%#{filter_search}%')"
          end    
        stdob =  MstCourseList.where(iswhere).order("crse_code ASC")
        return stdob
    end

    private
    def course_params
        params[:crse_compcode]	    = @compcodes
        params.permit(:crse_compcode,:crse_code,:crse_descp,:crse_duration,:crse_term,:crse_seats)
    end

    private
    def check_existing_uses_subject(subjectcode)
        @compcodes = session[:loggedUserCompCode]
        sewobj = MstSubjectList.where("sub_compcode = ? AND sub_crse = ?", @compcodes, subjectcode)
        sewobj.exists?
    end

    private
    def check_existing_uses_student(studentcode)
        @compcodes = session[:loggedUserCompCode]
        sewobj = MstStudentDtl.where("stdnt_dtl_compcode = ? AND stdnt_dtl_crse = ?", @compcodes, studentcode)
        sewobj.exists?
    end
end
