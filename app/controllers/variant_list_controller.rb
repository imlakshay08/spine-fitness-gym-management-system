class VariantListController < ApplicationController
  def index
    @variant_list = get_variant_list()
  end

  def add_variant
    if params[:id].to_i>0
      @variant= MstVariant.where("id=?",params[:id]).first
   end
  end

  def create
    isFlags = true
    mid = params[:mid]
    begin
      if params[:vt_description]== '' || params[:vt_description] == nil
        flash[:error] = "Description is Required"
        isFlags = false
      end
      currentgrp =  params[:vt_description].to_s.strip

      if mid.to_i>0
        if isFlags
            chkgrpobj   = MstVariant.where("id=?",mid).first
            if chkgrpobj
                chkgrpobj.update(variant_params)
                flash[:error] = "Data updated successfully"
                isFlags       = true
            end
        end
    else
        chkgrpobj   = MstVariant.where("id=? AND LOWER(vt_description)=?",mid,currentgrp.to_s.downcase)
            if isFlags
                savegrp = MstVariant.new(variant_params)
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
      redirect_to  "#{root_url}variant_list"
   else
      if params[:id].to_i>0 
          redirect_to  "#{root_url}variant_list/add_variant/"+params[:id].to_s
      else
          redirect_to  "#{root_url}variant_list/add_variant"
      end
        
    end
  end

  def referesh_variant_list
    session[:req_variant]  = nil
    redirect_to "#{root_url}variant_list"
  end

  def destroy
    if params[:id].to_i >0
         @ListSate =  MstVariant.where("id = ?",params[:id]).first
         if @ListSate
                   @ListSate.destroy
                   flash[:error] =  "Data deleted successfully."
                   isFlags       =  true
                   session[:isErrorhandled] = nil
         end
    end
    redirect_to "#{root_url}variant_list"
 end

 private
    def get_variant_list
      if params[:page].to_i >0
        pages = params[:page]
        else
        pages = 1
        end
        
      # if params[:server_request]!=nil && params[:server_request]!= ''
       
         session[:req_variant] = nil
      # end
      filter_search     = params[:variant] !=nil && params[:variant] != '' ? params[:variant].to_s.strip : session[:req_variant].to_s.strip       
      iswhere       = "id>0"
      if filter_search !=nil && filter_search !=''
        iswhere +=" AND ( vt_description LIKE '%#{filter_search}%')"
        @variant_list_search       = filter_search
        session[:req_variant] = filter_search
      end     
    
      stdob =  MstVariant.where(iswhere).paginate(:page =>pages,:per_page => 10).order("id ASC")
      return stdob
      end
      
      private
    def variant_params
      params.permit(:vt_description, :vt_status)
    end
end
