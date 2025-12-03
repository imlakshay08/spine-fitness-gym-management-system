class WdMasterController < ApplicationController
    before_action      :require_login
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct  
    before_action :set_city_and_branches, only: [:index, :add_wd]

    def index
        @Listbranch    = MstBranch.where(" Id=?",params[:id]).first
        @Listcity      = MstCity.where(" Id=?", params[:id]).first
        @wd_master    = get_wd_master()
    end

    def add_wd
        @Listbranch    = MstBranch.where(" Id=?",params[:id]).first
        @Listcity      = MstCity.where(" Id=?", params[:id]).first
        if params[:id].to_i>0
            @wd= MstWdmaster.where("Id=?",params[:id]).first
         end
    end

    def create
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:WDName] == '' || params[:WDName] == nil
           flash[:error] =  "WD Name is Required"
           isFlags = false
        end
        currentgrp =  params[:WDName].to_s.strip

        if mid.to_i>0
            if isFlags
                chkgrpobj   = MstWdmaster.where("Id=?",mid).first
                if chkgrpobj
                    chkgrpobj.update(wdmaster_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                end
            end
        else
            chkgrpobj   = MstWdmaster.where("Id=? AND LOWER(WDName)=?",mid,currentgrp.to_s.downcase)
                if isFlags
                    savegrp = MstWdmaster.new(wdmaster_params)
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
            redirect_to  "#{root_url}wd_master"
        else
            if params[:id].to_i>0 
                redirect_to  "#{root_url}wd_master/add_wd/"+params[:id].to_s
            else
                redirect_to  "#{root_url}wd_master/add_wd"
            end
              
        end

    end

    def referesh_wd_master
        session[:req_WD]  = nil
        redirect_to "#{root_url}wd_master"
     end


    def destroy
        if params[:id].to_i >0
             checkstatus = check_existing_master("WD",params[:id].to_i)
             if checkstatus
                    flash[:error] =  "Could not deleted due to used in receipt."
                    isFlags       =  false
                    session[:isErrorhandled] = 1
             else
                    @ListSate =  MstWdmaster.where("Id = ?",params[:id]).first
                    if @ListSate
                            @ListSate.destroy
                            flash[:error] =  "Data deleted successfully."
                            isFlags       =  true
                            session[:isErrorhandled] = nil
                    end
            end       
        end
        redirect_to "#{root_url}wd_master"
     end

    private
    def get_wd_master
          if params[:page].to_i >0
          pages = params[:page]
          else
          pages = 1
          end
          
        # if params[:server_request]!=nil && params[:server_request]!= ''
         
           session[:req_WD] = nil
        # end
        filter_search     = params[:WD] !=nil && params[:WD] != '' ? params[:WD].to_s.strip : session[:req_WD].to_s.strip       
        iswhere       = "id>0"
        if filter_search !=nil && filter_search !=''
          iswhere +=" AND ( WDName LIKE '%#{filter_search}%' OR WDCode LIKE '%#{filter_search}%')"
          @wd_master_search       = filter_search
          session[:req_WD] = filter_search
        end     
      
        stdob =  MstWdmaster.where(iswhere).paginate(:page =>pages,:per_page => 10).order("Id ASC")
        return stdob
    end

    private
    def wdmaster_params
        params.permit(:Ref_Branch_id,:Ref_City_id,:WDName,:WDCode,:Address_1,:Isactive)
    end

    def set_city_and_branches
        @cities   = MstCity.all
        @branches = MstBranch.all
    end
end
