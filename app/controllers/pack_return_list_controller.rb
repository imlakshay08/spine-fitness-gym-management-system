class PackReturnListController < ApplicationController
    before_action      :require_login
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct  
    helper_method :get_city_list, :get_wd_list, :get_activity_list, :get_brand_list, :get_variant_list
    def index
        @cities             = MstCity.all.order("City ASC")
        @stock_receipt_list = get_stock_receipt_list()
        @printnewPath       =  "stock_receipt_list/1_prt_stock_receipt.pdf"
        @printexcelPath     =  "stock_receipt_list/1_prt_list_stock_receipt.pdf"
    end

    def show
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'stock'
              entryno         = session[:id]
              @voucherdata    = print_stock_receipt_detail(entryno)
              @userDetail     = get_user_list(@voucherdata.Ref_user_id)
              @marketname     = get_city_list(@voucherdata.Ref_city_id)
              @Wddetail       = get_wd_list(@voucherdata.Ref_Wd_Id)
              @Activitydetail = get_activity_list(@voucherdata.Ref_Activity_id)
              @segmentdetail  = get_segment_list(@voucherdata.Segment_Type)
              @branddetail    = get_brand_list(@voucherdata.Ref_Brand_id)
              @variantdetail  = get_variant_list(@voucherdata.Brand_Variant)
              @packsize       = get_pack_size_list(@voucherdata.Pack_Size)
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = StockreceiptPdf.new(@voucherdata,rooturl,@userDetail,@marketname,@Wddetail,@Activitydetail,@segmentdetail,@branddetail,@variantdetail,@packsize)
                         send_data pdf.render,:filename => "1_#{@voucherdata.Id.to_s}_stock_receipt.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end
            elsif docsid[1] == 'prt' && docsid[2] == 'list'
                @get_time_now    = Date.today
                @excelObjx = nil   
                excelitems = process_excel_report()
                if @excelObjx
                    $excelitems = excelitems
                   
                    send_data @excelObjx.stock_receipt_list_excel, :filename=> "stock_receipt_list-#{Date.today}.csv"
                    return
                end

                end
            end
    end

    def refresh_pack_return_list
        session[:request_market_listed]  = nil 
        session[:request_from_dated]     = nil
        session[:request_upto_dated]     = nil
        session[:request_filter_by_date] = nil
        redirect_to "#{root_url}pack_return_list"
     end
     

     def destroy
        isFlags = false
        if params[:id].to_i >0
            chkgrpobj   = Transactionmaster.where("Id=?",params[:id].to_i).first
            if chkgrpobj
                if chkgrpobj.destroy
                    flash[:error] = "Data deleted successfully"
                    isFlags       = true
                end

            end
        end
        if !isFlags
            session[:isErrorhandled] = 1              
        else
            session[:isErrorhandled] = nil
            session[:postedpamams]   = nil
            isFlags = true
        end
        redirect_to  "#{root_url}pack_return_list"

   end

   def ajax_process
        if params[:identity]!=nil && params[:identity]!='' && params[:identity] == 'Y'
            get_stock_receipt_detail_print();
            return
        end
   end


   private
def get_stock_receipt_detail_print
    session[:id] = params[:entryno]
    isflags = true
    respond_to do |format|
      format.json { render :json => { 'data'=>'', "message"=>'',:status=>isflags} }
    end
end


    private
    def get_stock_receipt_list
          if params[:page].to_i >0
          pages = params[:page]
          else
          pages = 1
          end
          
        if params[:server_request]!=nil && params[:server_request]!= ''         
            session[:request_market_listed]  = nil 
            session[:request_from_dated]     = nil
            session[:request_upto_dated]     = nil
            session[:request_filter_by_date] = nil
         
        end

        market_listed     = params[:market_listed].to_s.present? ? params[:market_listed] : session[:request_market_listed]
        from_dated        = params[:from_dated].to_s.present?  ? params[:from_dated].to_s.strip : session[:request_from_dated] 
        upto_dated        = params[:upto_dated].to_s.present?  ? params[:upto_dated].to_s.strip : session[:request_upto_dated]         
        filter_by_date    = params[:filter_by_date].to_s.present?  ? params[:filter_by_date].to_s.strip : session[:request_filter_by_date] 
             
        iswhere       = "id>0 AND stock_type='PCK'"
        if market_listed.to_s.present?
            iswhere +=" AND Ref_city_id='#{market_listed}'"
            @market_listed       = market_listed
            session[:request_market_listed] = market_listed
        end 

         if filter_by_date.to_s.present?
                @filter_by_date                   = filter_by_date
                session[:request_filter_by_date]  = filter_by_date
                if from_dated.to_s.present?
                    iswhere +=" AND Date_of_pickup>='#{year_month_days_formatted(from_dated)}'"
                    @from_dated       = from_dated
                    session[:request_from_dated] = from_dated
                end 
                if upto_dated.to_s.present?
                    iswhere +=" AND Date_of_pickup<='#{year_month_days_formatted(upto_dated)}'"
                    @upto_dated       = upto_dated
                    session[:request_from_dated] = upto_dated
                end   
          
        end         
      
        stdob =  Transactionmaster.where(iswhere).paginate(:page =>pages,:per_page => 10).order("Id ASC")
        return stdob
    end

    
        private
        def print_stock_receipt_detail(entryno)
            iswhere  = "id>0 "
        if entryno !=nil && entryno!=''
        iswhere += " AND id='#{entryno}'"
        @entryno = entryno
        end   
        listobj	= Transactionmaster.where(iswhere).first
        return listobj
        end

        private
        def process_excel_report()
            
           myflags           = false
           market_listed     = session[:request_market_listed]
           from_dated        = session[:request_from_dated] 
           upto_dated        = session[:request_upto_dated]         
           filter_by_date    = session[:request_filter_by_date] 
                
      
        #    session[:rqs_server_request] = params[:server_request]
                     
              iswhere    = "id>0"; 
          
              if market_listed.to_s.present?
                iswhere +=" AND Ref_city_id='#{market_listed}'"
            end 
    
             if filter_by_date.to_s.present?
                @filter_by_date                   = filter_by_date
                session[:request_filter_by_date]  = filter_by_date
                    if from_dated.to_s.present?
                        iswhere +=" AND Date_of_pickup>='#{year_month_days_formatted(from_dated)}'"
                    end 
                    if upto_dated.to_s.present?
                        iswhere +=" AND Date_of_pickup<='#{year_month_days_formatted(upto_dated)}'"
                    end   
              
            end         
           isselect  = "transactionmasters.*,'' as transactionid,''as activitytype,''as activityname,''as agency,''as receivername,''as receiverdesignation,''as receivermobileno,''as cityname"
            isselect  += ",''as branchname,''as wdname,''as wdaddress,''as segmentname,''as brandname,''as variantname,''as packsize"
            stdob =  Transactionmaster.select(isselect).where(iswhere).order("Id ASC")
            arritem  = []
        
            if stdob.length >0
                @excelObjx = stdob
                stdob.each do |newitesm|
         
                    activityobj = get_activity_list(newitesm.Ref_Activity_id)
                    if activityobj
                        newitesm.activitytype = activityobj.activity_type
                        newitesm.activityname = activityobj.activity_name
                    end
                    userobj = get_user_list(newitesm.Ref_user_id)
                    if userobj
                        newitesm.agency              = userobj.agency
                        newitesm.receivername        = userobj.firstname
                        newitesm.receiverdesignation = userobj.designation
                        newitesm.receivermobileno    = userobj.phonenumber
                    end
                    marketobj = get_city_list(newitesm.Ref_city_id)
                    if marketobj
                        newitesm.cityname = marketobj.City
                        branchobj = get_branch_list(marketobj.Ref_Branch_id)
                        if branchobj
                            newitesm.branchname = branchobj.Branch_Code
                        end
                    end
                    wdobj = get_wd_list(newitesm.Ref_Wd_Id)
                    if wdobj
                        newitesm.wdname    = wdobj.WDName
                        newitesm.wdaddress = wdobj.Address_1
                    end
                    segmentobj = get_segment_list(newitesm.Segment_Type)
                    if segmentobj
                        newitesm.segmentname    = segmentobj.seg_description
                    end
                    brandobj = get_brand_list(newitesm.Ref_Brand_id)
                    if brandobj
                        newitesm.brandname    = brandobj.Brand_Name
                    end
                    variantobj = get_variant_list(newitesm.Brand_Variant)
                    if variantobj
                        newitesm.variantname    = variantobj.vt_description
                    end
                    packsizeobj = get_pack_size_list(newitesm.Pack_Size)
                    if packsizeobj
                        newitesm.packsize    = packsizeobj.ps_packsize
                    end
                     arritem.push newitesm
                end
                 
          return arritem
           end
       
        end
        

    def get_city_list(mid)
        cityobj = MstCity.where("id=?",mid).first
        return cityobj

    end

    def get_branch_list(mid)
        cityobj = MstBranch.where("id=?",mid).first
        return cityobj

    end



    def get_wd_list(mid)
        wdobj = MstWdmaster.where("id=?",mid).first
        return wdobj

    end

    def get_activity_list(mid)
        activityobj = MstActivity.where("id=?",mid).first
        return activityobj

    end

    def get_brand_list(mid)
        brandobj = MstBrandVariant.where("id=?",mid).first
        return brandobj

    end

    def get_variant_list(mid)
        variantobj = MstVariant.where("id=?",mid).first
        return variantobj
    end

    def get_segment_list(mid)
        segmentobj = MstSegment.where("id=?",mid).first
        return segmentobj

    end

    def get_pack_size_list(mid)
        packsizeobj = MstPackSize.where("id=?",mid).first
        return packsizeobj

    end


    def get_user_list(mid)
        userobj = MstUser.where("id=?",mid).first
        return userobj

    end


end
