class CityListController < ApplicationController
    before_action      :require_login
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct  
    before_action :set_agencies_and_branches, only: [:index, :add_city]

    def index 
        @Listbranch    = MstBranch.where(" Id=?",params[:id]).first
        @Listagency    = MstAgency.where(" Id=?",params[:id]).first
        @cityList = get_city_list() 
    end

    def add_city
        @Listbranch    = MstBranch.where(" Id=?",params[:id]).first
        @Listagency    = MstAgency.where(" Id=?",params[:id]).first
        if params[:id].to_i>0
            @city= MstCity.where("Id=?",params[:id]).first
         end
    end

    def create
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:City] == '' || params[:City] == nil
           flash[:error] =  "City Required"
           isFlags = false
        end
        currentgrp =  params[:City].to_s.strip

        if mid.to_i>0
            if isFlags
                chkgrpobj   = MstCity.where("Id=?",mid).first
                if chkgrpobj
                    chkgrpobj.update(city_list_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                end
            end
        else
            chkgrpobj   = MstCity.where("Id=? AND LOWER(City)=?",mid,currentgrp.to_s.downcase)
                if isFlags
                    savegrp = MstCity.new(city_list_params)
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
            redirect_to  "#{root_url}city_list"
        else
            if params[:id].to_i>0 
                redirect_to  "#{root_url}city_list/add_city/"+params[:id].to_s
            else
                redirect_to  "#{root_url}city_list/add_city"
            end
              
        end

    end


    def referesh_city_list
        session[:req_City]  = nil
        redirect_to "#{root_url}city_list"
     end


    def destroy
        if params[:id].to_i >0
            checkstatus = check_existing_master("CITY",params[:id].to_i)
                if checkstatus
                        flash[:error] =  "Could not deleted due to used in receipt."
                        isFlags       =  false
                        session[:isErrorhandled] = 1
                else
                    @ListSate =  MstCity.where("Id = ?",params[:id]).first
                    if @ListSate
                            @ListSate.destroy
                            flash[:error] =  "Data deleted successfully."
                            isFlags       =  true
                            session[:isErrorhandled] = nil
                    end

               end
        end
        redirect_to "#{root_url}city_list"
     end

    private
    def get_city_list
          if params[:page].to_i >0
          pages = params[:page]
          else
          pages = 1
          end
          
        # if params[:server_request]!=nil && params[:server_request]!= ''
         
           session[:req_City] = nil
        # end
        filter_search     = params[:City] !=nil && params[:City] != '' ? params[:City].to_s.strip : session[:req_City].to_s.strip       
        iswhere           = "id>0"
        if filter_search !=nil && filter_search !=''
          iswhere +=" AND  City LIKE '%#{filter_search}%' "
          @city_list_search       = filter_search
          session[:req_City] = filter_search
        end     
      
        stdobj =  MstCity.where(iswhere).paginate(:page =>pages,:per_page => 10).order("Id ASC")
        return stdobj
    end

    private
        def city_list_params
        params.permit(:City,:Ref_Branch_id,:Ref_Agency_Id,:Isactive)
    end

    def set_agencies_and_branches
        @agencies = MstAgency.all
        @branches = MstBranch.all
      end

end
