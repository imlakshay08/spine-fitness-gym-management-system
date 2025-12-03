class AgencyListController < ApplicationController
    before_action      :require_login
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct  

    def index
      @agency_list = get_agency_list()
    end
  
    def add_agency
      if params[:id].to_i > 0
        @agency= MstAgency.where("Id=?",params[:id]).first
      end
    end
  
    def create
      isFlags = true
      mid = params[:mid]
      begin
        if params[:Agency_Short]== '' || params[:Agency_Short] == nil
          flash[:error] = "Code is Required"
          isFlags = false
        end
        currentgrp =  params[:Agency_Short].to_s.strip
  
        if mid.to_i>0
          if isFlags
              chkgrpobj   = MstAgency.where("Id=?",mid).first
              if chkgrpobj
                  chkgrpobj.update(agency_params)
                  flash[:error] = "Data updated successfully"
                  isFlags       = true
              end
          end
      else
          chkgrpobj   = MstAgency.where("Id=? AND LOWER(Agency_Short)=?",mid,currentgrp.to_s.downcase)
              if isFlags
                  savegrp = MstAgency.new(agency_params)
                  if savegrp.save
                      flash[:error] = "Data saved successfully"
                      isFlags       = true
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
        flash[:error] = "ERROR: #{exc.message}"
        session[:isErrorhandled] = 1
        session[:postedpamams] = params
        isFlags = false
      end
      
      if isFlags
        redirect_to  "#{root_url}agency_list"
     else
        if params[:id].to_i>0 
            redirect_to  "#{root_url}agency_list/add_agency/"+params[:id].to_s
        else
            redirect_to  "#{root_url}agency_list/add_agency"
        end
          
    end

end
  
  def referesh_agency_list
    session[:req_agency]  = nil
    redirect_to "#{root_url}agency_list"
  end

  def destroy
    if params[:id].to_i >0
         @ListSate =  MstAgency.where("Id = ?",params[:id]).first
         if @ListSate
                   @ListSate.destroy
                   flash[:error] =  "Data deleted successfully."
                   isFlags       =  true
                   session[:isErrorhandled] = nil
         end
    end
    redirect_to "#{root_url}agency_list"
 end

    private
    def get_agency_list
      if params[:page].to_i >0
        pages = params[:page]
        else
        pages = 1
        end
        
      # if params[:server_request]!=nil && params[:server_request]!= ''
       
         session[:req_agency] = nil
      # end
      filter_search     = params[:agency] !=nil && params[:agency] != '' ? params[:agency].to_s.strip : session[:req_agency].to_s.strip       
      iswhere       = "id>0"
      if filter_search !=nil && filter_search !=''
        iswhere +=" AND ( Agency_Short LIKE '%#{filter_search}%' OR Agency_Description LIKE '%#{filter_search}%')"
        @agency_list_search       = filter_search
        session[:req_agency] = filter_search
      end     
    
      stdob =  MstAgency.where(iswhere).paginate(:page =>pages,:per_page => 10).order("Id ASC")
      return stdob
      end
      
      private
    def agency_params
      params.permit(:Agency_Short, :Agency_Description, :Agency_Isactive)
    end
  
  end
  