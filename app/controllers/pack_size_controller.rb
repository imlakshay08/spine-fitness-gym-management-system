class PackSizeController < ApplicationController
  def index
    @pack_size = get_pack_size()
  end

  def add_packsize
    if params[:id].to_i>0
      @pack= MstPackSize.where("id=?",params[:id]).first
   end
  end

  def create
    isFlags = true
    mid = params[:mid]
    begin
      if params[:ps_packsize]== '' || params[:ps_packsize] == nil
        flash[:error] = "Pack Size is Required"
        isFlags = false
      end
      currentgrp =  params[:ps_packsize].to_s.strip

      if mid.to_i>0
        if isFlags
            chkgrpobj   = MstPackSize.where("id=?",mid).first
            if chkgrpobj
                chkgrpobj.update(pack_params)
                flash[:error] = "Data updated successfully"
                isFlags       = true
            end
        end
    else
        chkgrpobj   = MstPackSize.where("id=? AND LOWER(ps_packsize)=?",mid,currentgrp.to_s.downcase)
            if isFlags
                savegrp = MstPackSize.new(pack_params)
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
      redirect_to  "#{root_url}pack_size"
   else
      if params[:id].to_i>0 
          redirect_to  "#{root_url}pack_size/add_segment/"+params[:id].to_s
      else
          redirect_to  "#{root_url}pack_size/add_segment"
      end
        
    end
  end

  def referesh_pack_size
    session[:req_pack]  = nil
    redirect_to "#{root_url}pack_size"
  end

  def destroy
    if params[:id].to_i >0
         @ListSate =  MstPackSize.where("id = ?",params[:id]).first
         if @ListSate
                   @ListSate.destroy
                   flash[:error] =  "Data deleted successfully."
                   isFlags       =  true
                   session[:isErrorhandled] = nil
         end
    end
    redirect_to "#{root_url}pack_size"
 end

    private
    def get_pack_size
      if params[:page].to_i >0
        pages = params[:page]
        else
        pages = 1
        end
        
      # if params[:server_request]!=nil && params[:server_request]!= ''
       
         session[:req_pack] = nil
      # end
      filter_search     = params[:pack] !=nil && params[:pack] != '' ? params[:pack].to_s.strip : session[:req_pack].to_s.strip       
      iswhere       = "id>0"
      if filter_search !=nil && filter_search !=''
        iswhere +=" AND ( ps_packsize LIKE '%#{filter_search}%')"
        @pack_size_search       = filter_search
        session[:req_pack] = filter_search
      end     
    
      stdob =  MstPackSize.where(iswhere).paginate(:page =>pages,:per_page => 10).order("id ASC")
      return stdob
      end
      
      private
    def pack_params
      params.permit(:ps_packsize, :ps_status)
    end
end
