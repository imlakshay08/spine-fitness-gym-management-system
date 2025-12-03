class CategoryListController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    helper_method :check_existing_uses
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        @category_list = get_category_list()
        printPath     =  "category_list/1_prt_category_list.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'category'
              
              @categorydetail   = print_category_list()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = CategoryPdf.new(@categorydetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_category_list.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def add_category
        @compcodes      = session[:loggedUserCompCode] 
        @category = nil
        if params[:id].to_i>0
            @category= MstCategoryList.where("cat_compcode=? AND id=?",@compcodes,params[:id]).first
        end
    end

    def referesh_category_list
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        session[:req_category_list] = nil 
        isFlags = true
        redirect_to  "#{root_url}category_list"
    end

    def create
        @compcodes      = session[:loggedUserCompCode] 
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:cat_code].to_s.blank?
           flash[:error] =  "Stock Code is Required"
           isFlags = false
        end
        if params[:cat_descp].to_s.blank?
          flash[:error] =  "Stock Description is Required"
          isFlags = false
       end
        currentgrp =  params[:cur_cat_code].to_s.strip
        newgroup   =  params[:cat_code].to_s.strip

        if params[:mid].to_i>0
            if currentgrp.to_s.downcase != newgroup.to_s.downcase
                chkgrpobj   = MstCategoryList.where("cat_compcode=? AND LOWER(cat_code)=? ",@compcodes,newgroup.to_s.downcase)
                if chkgrpobj.length>0
                    flash[:error] = "Could not be create duplicate Stock."
                    isFlags        = false
                end
            end
    
          if isFlags
                chkgrpobj   = MstCategoryList.where("cat_compcode=? AND id=?",@compcodes,mid).first
                if chkgrpobj
                    chkgrpobj.update(category_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                    modulename = "Category List"
                    description = "Category List Update: #{params[:cat_code]}"
                    process_request_log_data("UPDATE", modulename, description)
                end
          end
        else
            chkgrpobj   = MstCategoryList.where("cat_compcode=? AND LOWER(cat_code)=?",@compcodes,newgroup.to_s.downcase)
            if chkgrpobj.length>0
              flash[:error] = "Could not be create duplicate Stock."
             isFlags        = false
            end
              if isFlags
                  savegrp = MstCategoryList.new(category_params)
                  if savegrp.save
                      flash[:error] = "Data saved successfully"
                      isFlags       = true
                      modulename = "Category List"
                      description = "Category List Save: #{params[:cat_code]}"
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
            redirect_to  "#{root_url}category_list"
        else
            if params[:mid].to_i>0 
                redirect_to  "#{root_url}category_list/add_category/"+params[:mid].to_s
            else
                redirect_to  "#{root_url}category_list/add_category"
            end
              
        end
    
    end

    def destroy
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i >0
            @ListSate =  MstCategoryList.where("cat_compcode=? AND id=?", @compcodes,params[:id].to_i).first
            if @ListSate
                chekobj =  check_existing_uses(@ListSate.id)
                if chekobj                   
                    flash[:error] =  "Sorry !! The Selected Stock could not be deleted as it is being used in Stock Transaction."
                    isFlags       =  true
                    session[:isErrorhandled] = 1
                else @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
            end
       end
       redirect_to "#{root_url}category_list"
    end

    private
    def get_category_list
        @compcodes      = session[:loggedUserCompCode] 
        if params[:page].to_i >0
            pages = params[:page]
            else
            pages = 1
            end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
            #  session[:req_category_list] = nil
          # end
          filter_search = params[:category_list] !=nil && params[:category_list] != '' ? params[:category_list].to_s.strip : session[:req_category_list].to_s.strip       
          iswhere       = "cat_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( cat_code LIKE '%#{filter_search}%' OR cat_descp LIKE '%#{filter_search}%')"
            @category_list_search       = filter_search
            session[:req_category_list] = filter_search
          end     
        
          stdob =  MstCategoryList.where(iswhere).order("cat_code ASC")
          return stdob

    end

    def print_category_list
        @compcodes      = session[:loggedUserCompCode] 
        iswhere         = "cat_compcode ='#{@compcodes}'"
        filter_search   = session[:req_category_list]   
        if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( cat_code LIKE '%#{filter_search}%' OR cat_descp LIKE '%#{filter_search}%')"
          end    
        stdob =  MstCategoryList.where(iswhere).order("cat_code ASC")
        return stdob
    end

    private
    def category_params
        params[:cat_compcode]	    = @compcodes
        params.permit(:cat_compcode,:cat_code,:cat_descp)
    end

    private
    def check_existing_uses(catcode)
        @compcodes = session[:loggedUserCompCode]
        sewobj = MstStudentDtl.where("stdnt_dtl_compcode = ? AND stdnt_dtl_cat = ?", @compcodes, catcode)
        sewobj.exists?
      end
end
