class BranchListController < ApplicationController
    before_action      :require_login
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct  

    def index 
      @branch_list = get_branch_list()
    end
  
    def add_branch 
      @branch = nil
      if params[:id].to_i > 0
        @branch = MstBranch.where("Id=?",params[:id]).first
      end
    end
  
    def create
      isFlags = true
      mid = params[:mid]
      begin
        if params[:Branch_Code].blank?
          flash[:error] = "Branch is Required"
          isFlags = false
        end
        currentgrp = params[:Branch_Code].to_s.strip
  
        if mid.to_i>0
          if isFlags
              chkgrpobj   = MstBranch.where("Id=?",mid).first
              if chkgrpobj
                  chkgrpobj.update(branch_params)
                  flash[:error] = "Data updated successfully"
                  isFlags       = true
              end
          end
      else
          chkgrpobj   = MstBranch.where("Id=? AND LOWER(Branch_Code)=?",mid,currentgrp.to_s.downcase)
              if isFlags
                  savegrp = MstBranch.new(branch_params)
                  if savegrp.save
                      flash[:error] = "Data saved successfully"
                      isFlags       = true
                  end
              end

      end
  
        if !isFlags
          session[:isErrorhandled] = 1
          session[:postedpamams] = params
        else
          session[:isErrorhandled] = nil
          session[:postedpamams] = nil
        end
      rescue Exception => exc
        flash[:error] = "ERROR: #{exc.message}"
        session[:isErrorhandled] = 1
        session[:postedpamams] = params
        isFlags = false
      end
  
      if isFlags
        redirect_to "#{root_url}branch_list"
      else
        if params[:id].to_i > 0 
          redirect_to "#{root_url}branch_list/add_branch/"+params[:id].to_s
        else
          redirect_to "#{root_url}branch_list/add_branch"
        end
      end
    end

    def referesh_branch_list
      session[:req_branch]  = nil
      redirect_to "#{root_url}branch_list"
   end

    def destroy
        if params[:id].to_i >0
             @ListSate =  MstBranch.where("Id = ?",params[:id]).first
             if @ListSate
                       @ListSate.destroy
                       flash[:error] =  "Data deleted successfully."
                       isFlags       =  true
                       session[:isErrorhandled] = nil
             end
        end
        redirect_to "#{root_url}branch_list"
     end
    
    private
    def get_branch_list
      if params[:page].to_i >0
        pages = params[:page]
        else
        pages = 1
        end
        
      # if params[:requestserver]!=nil && params[:requestserver]!= ''
       
         session[:req_branch] = nil
      # end
      filter_search     = params[:branch] !=nil && params[:branch] != '' ? params[:branch].to_s.strip : session[:req_branch].to_s.strip       
      iswhere       = "id>0"
      if filter_search !=nil && filter_search !=''
        iswhere +=" AND ( Branch_Code LIKE '%#{filter_search}%' OR District LIKE '%#{filter_search}%')"
        @branch_list_search       = filter_search
        session[:req_branch] = filter_search
      end     
    
      std =  MstBranch.where(iswhere).paginate(:page =>pages,:per_page => 10).order("Id ASC")
      return std
    end

    def branch_params
      params.permit(:Branch_Code, :District, :Isactive)
    end

  end
  