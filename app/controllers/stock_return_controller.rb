class StockReturnController < ApplicationController
    before_action      :require_login
    skip_before_action :verify_authenticity_token, only: [:index,]   
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct   

    def index
        @LastcodeRTN=generate_regularization_series('RTN')
         @AddressListed = nil
         @ActivityNames = nil  
         @UserList      = nil
         if session[:autherizedUserId]
            @UserList = get_user_list(session[:autherizedUserId])  
         end
         mycityid = 0
         if params[:id].to_i>0
             @transaction = Transactionmaster.where("Id=?",params[:id]).first
             if  @transaction
                 mycityid       = @transaction.Ref_city_id
                 @AddressListed = print_address_for_wd(@transaction.Ref_Wd_Id)
                 chkgrpobj      = MstActivity.where("Id=?",@transaction.Ref_Activity_id).first
                 if chkgrpobj                     
                    @ActivityNames = chkgrpobj.activity_name                     
                 end
             end
         end
         set_agencies(mycityid)          
       
    end

    

    def stock_return_refresh
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        isFlags = true
        redirect_to  "#{root_url}stock_return"
    end

    def create
        
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:Ref_city_id].to_s.blank?
           flash[:error] =  "Market name is required" 
           isFlags = false      
        elsif params[:Ref_Wd_Id].to_s.blank?
            flash[:error] =  "WD name is required" 
            isFlags = false      
        elsif params[:Ref_Activity_id].to_s.blank?
            flash[:error] =  "Activity type is required" 
            isFlags = false      
        elsif params[:Segment_Type].to_s.blank?
            flash[:error] =  "Segment type is required" 
            isFlags = false      
        elsif params[:Ref_Brand_id].to_s.blank?
            flash[:error] =  "Brand is required" 
            isFlags = false      
        elsif params[:Ref_Brand_id].to_s.blank?
            flash[:error] =  "Brand is required" 
            isFlags = false      
        elsif params[:Brand_Variant].to_s.blank?
            flash[:error] =  "Brand Variant is required" 
            isFlags = false      
        elsif params[:Pack_Size].to_s.blank?
            flash[:error] =  "Pack size is required" 
            isFlags = false      
        elsif params[:Date_of_pickup].to_s.blank?
            flash[:error] =  "Date of pack is required" 
            isFlags = false      
        elsif params[:StockQty_pickup].to_s.blank?
            flash[:error] =  "Stock pick up is required" 
            isFlags = false      
        elsif params[:Value_for_stock].to_s.blank?
            flash[:error] =  "Value of stock is required" 
            isFlags = false      
        elsif params[:Rate_per_Stick].to_s.blank?
            flash[:error] =  "Rate per stick is required" 
            isFlags = false
        # elsif params[:Stock_receiver_Name].to_s.blank?
        #     flash[:error] =  "Stock Receiver Name is required" 
        #     isFlags = false
        # elsif params[:Stock_receiver_Designation].to_s.blank?
        #     flash[:error] =  "Stock Receiver Designation is required" 
        #     isFlags = false
        # elsif params[:Stock_receiver_MobileNo].to_s.blank?
        #     flash[:error] =  "Stock Receiver Mobile No. is required" 
        #     isFlags = false      
         end

         if isFlags
                    if mid.to_i>0
                         
                        chkgrpobj   = Transactionmaster.where("Id=?",mid).first
                        if chkgrpobj
                            chkgrpobj.update(stock_receipt_params)
                            flash[:error] = "Data updated successfully"
                            isFlags       = true
                        end
                            
                    else      
                         
                                
                            savegrp = Transactionmaster.new(stock_receipt_params)
                            if savegrp.save
                                flash[:error] = "Data saved successfully"
                                isFlags       = true
                            end
                            

                    end
        end            
      
        if !isFlags
                session[:isErrorhandled] = 1
                #session[:postedpamams]   = params
        else
                session[:isErrorhandled] = nil
                session[:postedpamams]   = nil
                isFlags = true
        end
        rescue Exception => exc
                flash[:error]            =  "ERROR: #{exc.message}"
                session[:isErrorhandled] = 1            
                isFlags = false
        end
        
        if isFlags
             redirect_to  "#{root_url}stock_return_list"
        else            
            redirect_to  "#{root_url}stock_return"
        end 
        
    end
   

    def stock_receipt_params
        params[:Rate_per_Stick]       = params[:Rate_per_Stick].to_s.present? ? params[:Rate_per_Stick] : 0
        params[:StockQty_pickup]      = params[:StockQty_pickup].to_s.present? ? params[:StockQty_pickup] : 0
        params[:Value_for_stock]      = params[:Value_for_stock].to_s.present? ? params[:Value_for_stock] : 0
        params[:Date_of_pickup]       = params[:Date_of_pickup].to_s.present? ? year_month_days_formatted(params[:Date_of_pickup]) : 0
        params[:Stock_receiver_Name]  = params[:Stock_receiver_Name].to_s.present? ? params[:Stock_receiver_Name] : ''
        params[:Pack_Size]            = params[:Pack_Size].to_s.present? ? params[:Pack_Size] : 0
        params[:Segment_Type]         = params[:Segment_Type].to_s.present? ? params[:Segment_Type] : ''
        params[:stock_type]           = params[:stock_type].to_s.present? ? params[:stock_type] : 'RTN'
        params[:Ref_user_id]          = session[:autherizedUserId]
        params[:Receipt_prepare_date] = Date.today
        params[:Receipt_prepare_time] = Time.now.strftime("%H:%I")     

        params.permit(
                    :Receipt_prepare_date,:Activity_Brief_Number,:Remarks,:Brand_Variant,:Pack_Size,
                    :Receipt_prepare_time,:Ref_user_id,:Ref_city_id,:Ref_Wd_Id,:Ref_Brand_id,:Ref_Activity_id,
                    :Date_of_pickup,:StockQty_pickup,:Value_for_stock,:Value_for_stock,:Stock_receiver_Name,
                    :Stock_receiver_Designation,:Stock_receiver_MobileNo,:Segment_Type,:Rate_per_Stick,:stock_type,:stock_no
        )
    end
 
    def set_agencies(mid=0)
        @agencies      =    MstAgency.all.order("Agency_Short ASC")
        @brands        =    MstBrandVariant.all.order("Variant_Name ASC")
        @wd            =    nil
        if mid.to_i>0
            @wd =     MstWdmaster.where("Ref_City_id=?",mid).order("WDName ASC")
        end
        @segments      =    MstSegment.all.order("seg_shortcode ASC")
        @variants      =    MstVariant.all.order("vt_description ASC")
        @pack_size     =    MstPackSize.all.order("ps_packsize ASC")
        @activities    =    MstActivity.all.order("activity_type ASC")
        @cities        =    MstCity.all.order("City ASC")
    end

    

    def print_address_for_wd(mid)       
        address     = ""
        chkgrpobj   = MstWdmaster.select("Address_1,Address_2,Address_3").where("Id=?",mid).first
        if chkgrpobj          
                address = chkgrpobj.Address_1
                if chkgrpobj.Address_2.to_s.present?
                    address +", "+chkgrpobj.Address_2.to_s    
                end
                if chkgrpobj.Address_3.to_s.present?
                    address +", "+chkgrpobj.Address_3.to_s    
                end
        end
      return address

    end

    private
    def generate_regularization_series(stock_type)
        is_code = 0
        rec_codes = Transactionmaster
                     .select(:Id, :stock_no)
                     .where("stock_type = ?", stock_type)
                     .where.not(stock_no: '')
                     .order(Arel.sql('CAST(stock_no AS UNSIGNED) DESC'))
                     .first
        
        if rec_codes
          is_code1 = rec_codes.stock_no.gsub(/[^\d]/, '')
          is_code = is_code1.to_i
        end
      
        sum_x_of_code = is_code + 1
        new_length = sum_x_of_code.to_s.length
        gen_length = @Startx.to_i - new_length
        zero_series = serial_global_number(gen_length)
        sum_x_of_code = zero_series.to_s + sum_x_of_code.to_s
        formatted_code = sum_x_of_code.to_s.rjust(5, '0')
      
        return formatted_code
       end
     
end
