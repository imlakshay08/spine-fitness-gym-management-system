class BrandVariantListController < ApplicationController
    
    def index 
        @brandVariant = get_brand_variant()
    end

    def add_brand_variant
        @Variant = nil
        if params[:id].to_i>0
            @Variant= MstBrandVariant.where("Id=?",params[:id]).first
         end
    end

    def create
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:Brand_Name] == '' || params[:Brand_Name] == nil
           flash[:error] =  "Brand Name Required"
           isFlags = false
        # elsif params[:Segment_Type] == '' || params[:Segment_Type] == nil
        #        flash[:error] =  "Segment Full Form Required"
        #        isFlags = false
        end
        currentgrp =  params[:Brand_Name].to_s.strip

        if mid.to_i>0
            if isFlags
                chkgrpobj   = MstBrandVariant.where("Id=?",mid).first
                if chkgrpobj
                    chkgrpobj.update(brand_variant_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                end
            end
        else
            chkgrpobj   = MstBrandVariant.where("Id=? AND LOWER(Brand_Name)=?",mid,currentgrp.to_s.downcase)
                if isFlags
                    savegrp = MstBrandVariant.new(brand_variant_params)
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
            redirect_to  "#{root_url}brand_variant_list"
        else
            if params[:id].to_i>0 
                redirect_to  "#{root_url}brand_variant_list/add_brand_variant/"+params[:id].to_s
            else
                redirect_to  "#{root_url}brand_variant_list/add_brand_variant"
            end
              
        end

    end

     def referesh_brand_variant_list
        session[:req_Vari]  = nil
        redirect_to "#{root_url}brand_variant_list"
     end


    def destroy
        if params[:id].to_i >0
             @ListSate =  MstBrandVariant.where("Id = ?",params[:id]).first
             if @ListSate
                       @ListSate.destroy
                       flash[:error] =  "Data deleted successfully."
                       isFlags       =  true
                       session[:isErrorhandled] = nil
             end
        end
        redirect_to "#{root_url}brand_variant_list"
     end

    private
    def get_brand_variant
          if params[:page].to_i >0
          pages = params[:page]
          else
          pages = 1
          end
          
        # if params[:requestserver]!=nil && params[:requestserver]!= ''
         
           session[:req_Vari] = nil
        # end
        filter_search     = params[:Vari] !=nil && params[:Vari] != '' ? params[:Vari].to_s.strip : session[:req_Vari].to_s.strip       
        iswhere       = "id>0"
        if filter_search !=nil && filter_search !=''
          iswhere +=" AND ( Variant_Name LIKE '%#{filter_search}%' OR Brand_Name LIKE '%#{filter_search}%')"
          @brand_variant_search       = filter_search
          session[:req_Vari] = filter_search
        end     
      
        stdobj =  MstBrandVariant.where(iswhere).paginate(:page =>pages,:per_page => 10).order("Id ASC")
        return stdobj
    end

    private
        def brand_variant_params
        params.permit(:Brand_Name,:Variant_Name,:Pack_Size,:Isactive)
    end
end
