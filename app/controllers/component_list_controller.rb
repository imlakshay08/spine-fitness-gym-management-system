class ComponentListController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @component_list = get_component_list()
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        printPath     =  "component_list/1_prt_component_list.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'component'
              
              @componentdetail   = print_component_list()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = ComponentPdf.new(@componentdetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_component_list.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def add_component
        @compcodes      = session[:loggedUserCompCode] 
        @component = nil
        if params[:id].to_i>0
            @component= MstComponentList.where("compt_compcode=? AND id=?",@compcodes,params[:id]).first
         end
    end

    def referesh_component_list
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        isFlags = true
        redirect_to  "#{root_url}component_list"
    end

    def create
        @compcodes      = session[:loggedUserCompCode] 
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:compt_code].to_s.blank?
           flash[:error] =  "Component Code is Required"
           isFlags = false
        end
        if params[:compt_descp].to_s.blank?
          flash[:error] =  "Component Description is Required"
          isFlags = false
       end
        currentgrp =  params[:cur_comp_code].to_s.strip
        newgroup   =  params[:compt_code].to_s.strip
        active     =  params[:compt_active].to_s.strip
    
        if params[:mid].to_i>0
            if currentgrp.to_s.downcase != newgroup.to_s.downcase
                chkgrpobj   = MstComponentList.where("compt_compcode=? AND LOWER(compt_code)=? ",@compcodes,newgroup.to_s.downcase)
                if chkgrpobj.length>0
                    flash[:error] = "Could not be create duplicate Course."
                    isFlags        = false
                end
            end
    
          if isFlags
                chkgrpobj   = MstComponentList.where("compt_compcode=? AND id=?",@compcodes,mid).first
                if chkgrpobj
                    chkgrpobj.update(component_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                    modulename = "Component List"
                    description = "Component List Update: #{params[:compt_code]}"
                    process_request_log_data("UPDATE", modulename, description)
                end
          end
        else
            chkgrpobj   = MstComponentList.where("compt_compcode=? AND LOWER(compt_code)=?",@compcodes,newgroup.to_s.downcase)
            if chkgrpobj.length>0
              flash[:error] = "Could not be create duplicate Assembly."
             isFlags        = false
            end
              if isFlags
                  savegrp = MstComponentList.new(component_params)
                  if savegrp.save
                      flash[:error] = "Data saved successfully"
                      isFlags       = true
                      modulename = "Component List"
                      description = "Component List Save: #{params[:compt_code]}"
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
            redirect_to  "#{root_url}component_list"
        else
            if params[:mid].to_i>0 
                redirect_to  "#{root_url}component_list/add_component/"+params[:mid].to_s
            else
                redirect_to  "#{root_url}component_list/add_component"
            end
              
        end
    
    end

    def destroy
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i >0
            @ListSate =  MstComponentList.where("compt_compcode=? AND id=?", @compcodes,params[:id].to_i).first
               if @ListSate
                     @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
       end
       redirect_to "#{root_url}component_list"
    end

    private
    def get_component_list
        @compcodes      = session[:loggedUserCompCode] 
        if params[:page].to_i >0
            pages = params[:page]
            else
            pages = 1
            end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
             session[:req_component_list] = nil
          # end
          filter_search = params[:component_list] !=nil && params[:component_list] != '' ? params[:component_list].to_s.strip : session[:req_component_list].to_s.strip       
          iswhere       = "compt_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( compt_code LIKE '%#{filter_search}%' OR compt_descp LIKE '%#{filter_search}%')"
            @component_list_search       = filter_search
            session[:req_component_list] = filter_search
          end     
        
          stdob =  MstComponentList.where(iswhere).order("compt_code ASC")
          return stdob

    end

    def print_component_list
        @compcodes      = session[:loggedUserCompCode] 
        iswhere         = "compt_compcode ='#{@compcodes}'"
        filter_search   = session[:req_component_list]   
        if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( compt_code LIKE '%#{filter_search}%' OR compt_descp LIKE '%#{filter_search}%')"
          end    
        stdob =  MstComponentList.where(iswhere).order("compt_code ASC")
        return stdob
    end

    private
    def component_params
        params[:compt_compcode]	    = @compcodes
        params.permit(:compt_compcode,:compt_code,:compt_descp,:compt_active)
    end
end
