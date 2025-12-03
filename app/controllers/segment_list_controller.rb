class SegmentListController < ApplicationController
  def index
    @segment_list = get_segment_list()
  end

  def add_segment
    if params[:id].to_i>0
      @segment= MstSegment.where("id=?",params[:id]).first
   end
  end

  def create
    isFlags = true
    mid = params[:mid]
    begin
      if params[:seg_shortcode]== '' || params[:seg_shortcode] == nil
        flash[:error] = "Code is Required"
        isFlags = false
      end
      currentgrp =  params[:seg_shortcode].to_s.strip

      if mid.to_i>0
        if isFlags
            chkgrpobj   = MstSegment.where("id=?",mid).first
            if chkgrpobj
                chkgrpobj.update(segment_params)
                flash[:error] = "Data updated successfully"
                isFlags       = true
            end
        end
    else
        chkgrpobj   = MstSegment.where("id=? AND LOWER(seg_shortcode)=?",mid,currentgrp.to_s.downcase)
            if isFlags
                savegrp = MstSegment.new(segment_params)
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
      redirect_to  "#{root_url}segment_list"
   else
      if params[:id].to_i>0 
          redirect_to  "#{root_url}segment_list/add_segment/"+params[:id].to_s
      else
          redirect_to  "#{root_url}segment_list/add_segment"
      end
        
    end
  end

  def referesh_segment_list
    session[:req_segment]  = nil
    redirect_to "#{root_url}segment_list"
  end

  def destroy
    if params[:id].to_i >0
         @ListSate =  MstSegment.where("id = ?",params[:id]).first
         if @ListSate
                   @ListSate.destroy
                   flash[:error] =  "Data deleted successfully."
                   isFlags       =  true
                   session[:isErrorhandled] = nil
         end
    end
    redirect_to "#{root_url}segment_list"
 end

    private
    def get_segment_list
      if params[:page].to_i >0
        pages = params[:page]
        else
        pages = 1
        end
        
      # if params[:server_request]!=nil && params[:server_request]!= ''
       
         session[:req_segment] = nil
      # end
      filter_search     = params[:segment] !=nil && params[:segment] != '' ? params[:segment].to_s.strip : session[:req_segment].to_s.strip       
      iswhere       = "id>0"
      if filter_search !=nil && filter_search !=''
        iswhere +=" AND ( seg_shortcode LIKE '%#{filter_search}%' OR seg_description LIKE '%#{filter_search}%')"
        @segment_list_search       = filter_search
        session[:req_segment] = filter_search
      end     
    
      stdob =  MstSegment.where(iswhere).paginate(:page =>pages,:per_page => 10).order("id ASC")
      return stdob
      end
      
      private
    def segment_params
      params.permit(:seg_shortcode, :seg_description, :seg_status)
    end
end
