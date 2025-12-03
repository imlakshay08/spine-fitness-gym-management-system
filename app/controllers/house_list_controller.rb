class HouseListController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        @house_list = get_house_list()
        printPath     =  "house_list/1_prt_club_list.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'house'
              
              @housedetail   = print_house_list()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = HousePdf.new(@housedetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_club_list.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def add_house
        @compcodes      = session[:loggedUserCompCode] 
        @house = nil
        if params[:id].to_i>0
            @house= MstHouseList.where("hs_compcode=? AND id=?",@compcodes,params[:id]).first
         end
    end

    def referesh_house_list
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        session[:req_house_list] = nil
        isFlags = true
        redirect_to  "#{root_url}house_list"
    end

    def create
        @compcodes      = session[:loggedUserCompCode] 
        isFlags     = true
        mid         = params[:mid] #House House_ID
        begin
        if params[:hs_house_name].to_s.blank?
           flash[:error] =  "Club Name is Required"
           isFlags = false
        end
       
        currentgrp =  params[:cur_hs_house_name].to_s.strip
        newgroup   =  params[:hs_house_name].to_s.strip
        if params[:mid].to_i>0
            if currentgrp.to_s.downcase != newgroup.to_s.downcase
                chkgrpobj   = MstHouseList.where("hs_compcode=? AND LOWER(hs_house_name)=?",@compcodes,newgroup.to_s.downcase)
                if chkgrpobj.length>0
                    flash[:error] = "Could not be create duplicate Club."
                    isFlags        = false
                end
            end
    
          if isFlags
                chkgrpobj   = MstHouseList.where("hs_compcode=? AND id=?",@compcodes,mid).first
                if chkgrpobj
                    chkgrpobj.update(house_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                    modulename = "House List"
                    description = "House List Update: #{params[:hs_house_name]}"
                    process_request_log_data("UPDATE", modulename, description)
                
                end
          end
        else
            chkgrpobj   = MstHouseList.where("hs_compcode=? AND LOWER(hs_house_name)=?",@compcodes,newgroup.to_s.downcase)
            if chkgrpobj.length>0
              flash[:error] = "Could not be create duplicate Club."
             isFlags        = false
            end
              if isFlags
                  savegrp = MstHouseList.new(house_params)
                  if savegrp.save
                      flash[:error] = "Data saved successfully"
                      isFlags       = true
                      modulename = "House List"
                    description = "House List Save: #{params[:hs_house_name]}"
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
            redirect_to  "#{root_url}house_list"
        else
            if params[:mid].to_i>0 
                redirect_to  "#{root_url}house_list/add_house/"+params[:mid].to_s
            else
                redirect_to  "#{root_url}house_list/add_house"
            end
              
        end
    end

    def destroy
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i >0
            @ListSate =  MstHouseList.where("hs_compcode=? AND id=?", @compcodes,params[:id].to_i).first
               if @ListSate
                     @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
       end
       redirect_to "#{root_url}house_list"
    end

    private
    def get_house_list
        @compcodes      = session[:loggedUserCompCode] 
        if params[:page].to_i >0
            pages = params[:page]
            else
            pages = 1
            end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
            #  session[:req_house_list] = nil
          # end
          filter_search = params[:house_list] !=nil && params[:house_list] != '' ? params[:house_list].to_s.strip : session[:req_house_list].to_s.strip       
          iswhere       = "hs_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( hs_house_name LIKE '%#{filter_search}%')"
            @house_list_search       = filter_search
            session[:req_house_list] = filter_search
          end     
        
          stdob =  MstHouseList.where(iswhere).order("hs_house_name ASC")
          return stdob
    end

    def print_house_list
        @compcodes      = session[:loggedUserCompCode] 
        iswhere         = "hs_compcode ='#{@compcodes}'"
        filter_search   = session[:req_house_list]   
        if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( hs_house_name LIKE '%#{filter_search}%')"
          end    
        stdob =  MstHouseList.where(iswhere).order("hs_house_name ASC")
        return stdob
    end

    private
    def house_params
        params[:hs_compcode]	    = @compcodes
        params.permit(:hs_compcode,:hs_house_name)
    end
end
