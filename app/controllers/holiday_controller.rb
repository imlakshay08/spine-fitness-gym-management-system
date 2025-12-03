class HolidayController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    helper_method :check_existing_uses
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        @holiday_list = get_holiday_list()
        printPath     =  "holiday/1_prt_holiday_list.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'holiday'
              
              @holidaydetail   = print_holiday_list()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = HolidayPdf.new(@holidaydetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_holiday_list.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def add_holiday
        @compcodes      = session[:loggedUserCompCode] 
        @holiday = nil
        if params[:id].to_i>0
            @holiday= MstHoliday.where("holiday_compcode=? AND id=?",@compcodes,params[:id]).first
        end
    end

    def referesh_holiday
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        session[:req_holiday_list] = nil 
        isFlags = true
        redirect_to  "#{root_url}holiday"
    end

    def create
        @compcodes      = session[:loggedUserCompCode] 
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:holiday_date].to_s.blank?
           flash[:error] =  "Date is Required"
           isFlags = false
        end
        if params[:holiday_descp].to_s.blank?
          flash[:error] =  "Holiday Description is Required"
          isFlags = false
       end
        currentgrp =  params[:cur_holiday_descp].to_s.strip
        newgroup   =  params[:holiday_descp].to_s.strip

        if params[:mid].to_i>0
            if currentgrp.to_s.downcase != newgroup.to_s.downcase
                chkgrpobj   = MstHoliday.where("holiday_compcode=? AND LOWER(holiday_descp)=? ",@compcodes,newgroup.to_s.downcase)
                if chkgrpobj.length>0
                    flash[:error] = "Could not be create duplicate Holiday."
                    isFlags        = false
                end
            end
    
          if isFlags
                chkgrpobj   = MstHoliday.where("holiday_compcode=? AND id=?",@compcodes,mid).first
                if chkgrpobj
                    chkgrpobj.update(holiday_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                    modulename = "Holiday"
                    description = "Holiday Update: #{params[:holiday_descp]}"
                    process_request_log_data("UPDATE", modulename, description)
                end
          end
        else
            chkgrpobj   = MstHoliday.where("holiday_compcode=? AND LOWER(holiday_descp)=?",@compcodes,newgroup.to_s.downcase)
            if chkgrpobj.length>0
              flash[:error] = "Could not be create duplicate Holiday."
             isFlags        = false
            end
              if isFlags
                  savegrp = MstHoliday.new(holiday_params)
                  if savegrp.save
                      flash[:error] = "Data saved successfully"
                      isFlags       = true
                      modulename = "Holiday List"
                      description = "Holiday List Save: #{params[:holiday_descp]}"
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
            redirect_to  "#{root_url}holiday"
        else
            if params[:mid].to_i>0 
                redirect_to  "#{root_url}holiday/add_holiday/"+params[:mid].to_s
            else
                redirect_to  "#{root_url}holiday/add_holiday"
            end
              
        end
    
    end

    def destroy
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i >0
            @ListSate =  MstHoliday.where("holiday_compcode=? AND id=?", @compcodes,params[:id].to_i).first
            if @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
       end
       redirect_to "#{root_url}holiday"
    end

    private
    def get_holiday_list
        @compcodes      = session[:loggedUserCompCode] 
        if params[:page].to_i >0
            pages = params[:page]
            else
            pages = 1
            end
            
          if params[:server_request]!=nil && params[:server_request]!= ''
           
             session[:req_holiday_list] = nil
          end
          filter_search = params[:holiday_list] !=nil && params[:holiday_list] != '' ? params[:holiday_list].to_s.strip : session[:req_holiday_list].to_s.strip       
          iswhere       = "holiday_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( holiday_descp LIKE '%#{filter_search}%')"
            @holiday_list_search       = filter_search
            session[:req_holiday_list] = filter_search
          end     
        
          stdob =  MstHoliday.where(iswhere).order("holiday_date ASC")
          return stdob

    end

    def print_holiday_list
        @compcodes      = session[:loggedUserCompCode] 
        iswhere         = "cat_compcode ='#{@compcodes}'"
        filter_search   = session[:req_holiday_list]   
        # if filter_search !=nil && filter_search !=''
        #     iswhere +=" AND ( cat_code LIKE '%#{filter_search}%' OR cat_descp LIKE '%#{filter_search}%')"
        #   end    
        stdob =  MstHoliday.where(iswhere).order("holiday_date ASC")
        return stdob
    end

    private
    def holiday_params
        params[:holiday_compcode]	    = @compcodes
        params.permit(:holiday_compcode,:holiday_date,:holiday_descp)
    end

    private
    def check_existing_uses(catcode)
        @compcodes = session[:loggedUserCompCode]
        sewobj = MstStudentDtl.where("stdnt_dtl_compcode = ? AND stdnt_dtl_cat = ?", @compcodes, catcode)
        sewobj.exists?
      end
end
