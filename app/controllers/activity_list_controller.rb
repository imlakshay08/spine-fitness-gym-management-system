class ActivityListController < ApplicationController
    before_action      :require_login
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct  

    def index
      @activity_list = get_activity_list()
      end
      
  
    def add_activity
      if params[:id].to_i>0
        @activity= MstActivity.where("id=?",params[:id]).first
     end    
    end
  
    def create
      isFlags     = true
      mid         = params[:mid]
      begin
      if params[:activity_name] == '' || params[:activity_name] == nil
         flash[:error] =  "Activity Name is Required"
         isFlags = false
      end
      if params[:activity_type] == '' || params[:activity_type] == nil
        flash[:error] =  "Activity Type is Required"
        isFlags = false
     end
      currentgrp =  params[:activity_name].to_s.strip

      if mid.to_i>0
          if isFlags
              chkgrpobj   = MstActivity.where("id=?",mid).first
              if chkgrpobj
                  chkgrpobj.update(activity_params)
                  flash[:error] = "Data updated successfully"
                  isFlags       = true
              end
          end
      else
          chkgrpobj   = MstActivity.where("id=? AND LOWER(activity_name)=?",mid,currentgrp.to_s.downcase)
              if isFlags
                  savegrp = MstActivity.new(activity_params)
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
          flash[:error] =  "ERROR: #{exc.message}"
          session[:isErrorhandled] = 1
          session[:postedpamams]   = params
          isFlags = false
      end
      if isFlags
          redirect_to  "#{root_url}activity_list"
      else
          if params[:id].to_i>0 
              redirect_to  "#{root_url}activity_list/add_activity/"+params[:id].to_s
          else
              redirect_to  "#{root_url}activity_list/add_activity"
          end
            
      end

  end
  
  def referesh_activity_list
    session[:req_activity]  = nil
    redirect_to "#{root_url}activity_list"
 end


  def destroy
    if params[:id].to_i >0
          checkstatus = check_existing_master("ACT",params[:id].to_i)
          if checkstatus
                  flash[:error] =  "Could not deleted due to used in receipt."
                  isFlags       =  false
                  session[:isErrorhandled] = 1
          else
                @ListSate =  MstActivity.where("id = ?",params[:id]).first
                if @ListSate
                          @ListSate.destroy
                          flash[:error] =  "Data deleted successfully."
                          isFlags       =  true
                          session[:isErrorhandled] = nil
                end

            end
    end
    redirect_to "#{root_url}activity_list"
 end

    private
    def get_activity_list
      if params[:page].to_i >0
        pages = params[:page]
        else
        pages = 1
        end
        
      # if params[:server_request]!=nil && params[:server_request]!= ''
       
         session[:req_activity] = nil
      # end
      filter_search     = params[:activity] !=nil && params[:activity] != '' ? params[:activity].to_s.strip : session[:req_activity].to_s.strip       
      iswhere       = "id>0"
      if filter_search !=nil && filter_search !=''
        iswhere +=" AND ( activity_name LIKE '%#{filter_search}%')"
        @activity_list_search       = filter_search
        session[:req_activity] = filter_search
      end     
    
      stdob =  MstActivity.where(iswhere).paginate(:page =>pages,:per_page => 10).order("id ASC")
      return stdob
    end
  
    private
    def activity_params
      params.permit(:activity_name,:activity_status,:WDName,:activity_type,:isactive)
    end

  end
  