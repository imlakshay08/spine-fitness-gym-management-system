class PackingListController < ApplicationController
   before_action :require_login
   before_action :allowed_pages
   before_action :is_allowed_location
   skip_before_action :verify_authenticity_token,:only=> [:ajax_process]
   include ErpModule::Common
   helper_method :currency_formatted,:get_selected_product_myprocess
   
  def index
    @compcodes            =  session[:loggedUserCompCode]
    @logedId              =  session[:autherizedUserId]
    @xLoc                 =  session[:autherizedLoc]
    @isFlags              =  false
    @cdate                =  Time.now.strftime('%d-%b-%Y')
    params[:hd_sale_type] = 'S'
    params[:hd_type]      = 'Export'
    @compObj              =  MstCompany.select("cmp_companycode,cmp_companyname").all.order('cmp_companyname ASC')
    month_number          =  Time.now.month
    month_begin           =  Date.new(Date.today.year, month_number)
    begdate               =  Date.parse(month_begin.to_s)
    @nbegindate           =  begdate.strftime('%d-%b-%Y')
    month_ending          =  month_begin.end_of_month
    endingDate            =  Date.parse(month_ending.to_s)
    @enddate              =  endingDate.strftime('%d-%b-%Y')    
    @LastPackNo           =  get_last_pack_number
    
    @HeadPack             =  nil
    @FootPack             =  nil
    @Customer             =  nil
    @printpath            =  nil
    @rootUrl              =  "#{root_url}"
    ################### PROCESS PACK LISTING Settings################
     if params[:id]!=nil && params[:id]!=''
         dparmes  = params[:id].split("_")
        if dparmes[1]!='PLC' && dparmes[1]!='EXCEL'
          nlid                =  Base64.decode64(params[:id])
          prntid              =  params[:id]
          plid                =  nlid.split("_")
          pnnumber            =  plid[0]
          comxcode            =  plid[1]
          typecode            =  plid[2]
          params[:hd_type]    =  typecode
          params[:comp_codes] =  comxcode
          @AllPackList        =  get_packlist_all_bills
          @LastOABills        =  get_orderno_details
          @HeadPack           =  TrnPackingList.where("pl_compcode=? AND pl_number=? AND pl_local_type=?",comxcode,pnnumber,typecode).first
          oanumber            =  @HeadPack.pl_oa_number
          @FootPack           =  TrnPackingListDetail.where("pld_compcode=? AND pld_number=? AND pld_locality_type=?",comxcode,pnnumber,typecode).order(Arel.sql("CAST(SUBSTRING_INDEX(pld_box_no, '-', 1) AS UNSIGNED) ASC"))
          
          
          
          @Customer           =  TrnProformaHdr.select("hd_invoiceto,hd_dispmode,hd_billnumber,hd_po_number").where(["hd_compcode = ? AND hd_sale_type= ? AND hd_type=? AND hd_billnumber=?", comxcode,params[:hd_sale_type],typecode,oanumber]).first
          session[:isprintableid] = prntid
          printcontroll    = pnnumber.to_s+"_PLC_"+pnnumber.to_s+"_pcklist_report"
          @printpath       = packing_list_path(printcontroll,:format=>"pdf")
          printcontrollsec    = pnnumber.to_s+"_EXCEL_pcklist_report"
          @printexcelpath     = packing_list_path(printcontrollsec,:format=>"pdf")
        end
        if dparmes[1]=='PLC'
          nlid      = Base64.decode64(session[:isprintableid])         
          plid      = nlid.split("_")
          pnnumber  = plid[0]
          comxcode  = plid[1]
          typecode  = plid[2]
          @compDetail= MstCompany.where(["cmp_companycode = ?", @compcodes]).first
          @HeadPack = TrnPackingList.where("pl_compcode=? AND pl_number=? AND pl_local_type=?",comxcode,pnnumber,typecode).first
          oanumber  = @HeadPack.pl_oa_number
          custid    =  @HeadPack.pl_customer_id
          @FootPack = TrnPackingListDetail.select("trn_packing_list_details.*,'' as oemname,'' as ponumber,''as productname").where("pld_compcode=? AND pld_number=? AND pld_locality_type=?",comxcode,pnnumber,typecode).order("pld_position ASC")
          @Customer = TrnProformaHdr.select("hd_invoiceto,hd_dispmode,hd_billnumber,hd_po_number,hd_station").where(["hd_compcode = ? AND hd_sale_type= ? AND hd_type=? AND hd_billnumber=?", comxcode,params[:hd_sale_type],typecode,oanumber]).first
          @newCustomer = MstCustomer.where("cs_compcode = ? AND id=?",@compcodes,custid).first
          @palletDetail = TrnPalletDetail.where("pallt_compcode=? AND pl_pllt_packing_no=? ",comxcode,pnnumber).order("pallt_no ASC")
          arr  = []
          if @FootPack.length >0
            @FootPack.each do |fds|
                compcode = fds.pld_compcode
                jono     = fds.pld_oa_number
                types    = fds.pld_locality_type
                itemcode = fds.pld_itemcode
                objjo      = get_all_po_no_agaist_jono(compcode,jono,types)
                if objjo
                  fds.ponumber = objjo.hd_po_number
                end
                productdetail = get_selected_product_myprocess(itemcode)
                if productdetail
                  fds.productname = productdetail.pd_productname
                end
                joborderoem = get_joborder_oem_detail(itemcode,jono)
                if joborderoem
                  fds.oemname = joborderoem.dt_oem
                end
                arr.push fds
            end
             @FootPack = arr
              respond_to do |format|
                format.html
                  format.pdf do
                      pdf = PacklistingPdf.new(@FootPack,@HeadPack,@newCustomer,@compDetail,@Customer,@rootUrl,'','',session,'',@palletDetail)
                      send_data pdf.render,:filename => "1_"+pnnumber.to_s+"_pack_report.pdf", :type => "application/pdf", :disposition => "inline"
                  end
             end
           end
         elsif dparmes[1]=='EXCEL'
            nlid      = Base64.decode64(session[:isprintableid]) 
            plid      = nlid.split("_")
            pnnumber  = plid[0]
            comxcode  = plid[1]
            typecode  = plid[2]
            @compDetail= MstCompany.where(["cmp_companycode = ?", @compcodes]).first
            @HeadPack = TrnPackingList.where("pl_compcode=? AND pl_number=? AND pl_local_type=?",comxcode,pnnumber,typecode).first
            oanumber  = @HeadPack.pl_oa_number
            custid    =  @HeadPack.pl_customer_id
            @FootPack = TrnPackingListDetail.select("trn_packing_list_details.*,'' as oemname,'' as ponumber,''as productname,'' as packingdate,'' as packingno,'' as buyer").where("pld_compcode=? AND pld_number=? AND pld_locality_type=?",comxcode,pnnumber,typecode).order("pld_position ASC")
            @Customer = TrnProformaHdr.select("hd_invoiceto,hd_dispmode,hd_billnumber,hd_po_number,hd_station").where(["hd_compcode = ? AND hd_sale_type= ? AND hd_type=? AND hd_billnumber=?", comxcode,params[:hd_sale_type],typecode,oanumber]).first
            @newCustomer = MstCustomer.where("cs_compcode = ? AND id=?",@compcodes,custid).first
            arr  = []
            if @FootPack.length >0
            #   @excelObjx = @FootPack
              @FootPack.each do |fds|
                  compcode = fds.pld_compcode
                  jono     = fds.pld_oa_number
                  types    = fds.pld_locality_type
                  itemcode = fds.pld_itemcode
                  fds.packingdate = @HeadPack.pl_date
                  fds.packingno   = @HeadPack.pl_number
                  fds.buyer       = @HeadPack.pl_customername
                  objjo      = get_all_po_no_agaist_jono(compcode,jono,types)
                  if objjo
                    fds.ponumber = objjo.hd_po_number
                  end
                  productdetail = get_selected_product_myprocess(itemcode)
                  if productdetail
                    fds.productname = productdetail.pd_productname
                  end
                  joborderoem = get_joborder_oem_detail(itemcode,jono)
                  if joborderoem
                    fds.oemname = joborderoem.dt_oem
                  end

                  arr.push fds
              end
              # @FootPack = arr
            if @FootPack  
               $excelitems = arr
               send_data @FootPack.packing_list_excel, :filename=> "1_"+pnnumber.to_s+"packing_list_excel-#{Date.today}.csv"
               return
             end
           end

        end
     else
      

          @AllPackList    =  get_packlist_all_bills
          @LastOABills    =  get_orderno_details
      end
    ####################################
   
    session[:generatecustid] = nil
    session[:generateshipid] = nil
    
end
######PROCESS AJAX RULE FOR CREATE PACKING LIST ###########
def ajax_process
  @compcodes = session[:loggedUserCompCode]
  if params[:isProductName]!=nil &&  params[:isProductName]!='' && params[:isProductName]=='TRNLP'
     get_last_order_details()
     return
  elsif params[:isProductName]!=nil &&  params[:isProductName]!='' && params[:isProductName]=='CUSTOMER'
     get_customer_details()
     return
  elsif params[:isProductName]!=nil &&  params[:isProductName]!='' && params[:isProductName]=='OAN'
     get_search_prdname_by_oano()
     return
  elsif params[:isProductName]!=nil &&  params[:isProductName]!='' && params[:isProductName]=='JOBOD'
     get_search_by_joborders()
     return
  elsif params[:isProductName]!=nil &&  params[:isProductName]!='' && params[:isProductName]=='BOXPLT'
     set_pallet_box_detail()
     return
  elsif params[:isProductName]!=nil &&  params[:isProductName]!='' && params[:isProductName]=='PKPRT'
      check_print_pallet()
      return
  elsif params[:identity]!=nil &&  params[:identity]!='' && params[:identity]=='ADDPACKLIST'
      process_create_packing_list()
      return
  elsif params[:identity]!=nil &&  params[:identity]!='' && params[:identity]=='DELPCKLIST'
      delete_process_packing_list()
      return
  elsif params[:identity]!=nil &&  params[:identity]!='' && params[:identity]=='UPDHEAD'
      update_header_footer_detais()
      return
  end

  
  
  
end


def process_create_packing_list
  comp_codes   =  input_escape(params[:hd_company]).to_s.present? ? input_escape(params[:hd_company]) : @compcodes
  comp_type    =  input_escape(params[:hd_type]).to_s.present? ? input_escape(params[:hd_type]) :'Local'
  plnumber     =  input_escape(params[:pl_number]).to_s.present? ?  input_escape(params[:pl_number]).to_s.strip : ''
  pl_date      =  input_escape(params[:pl_date]).to_s.present? ?  input_escape(params[:pl_date]).to_s.strip : ''
  joborder     =  input_escape(params[:pld_oa_number]).to_s.present? ?  input_escape(params[:pld_oa_number]).to_s.strip : ''
  buyers       =  input_escape(params[:pl_customer_id]).to_s.present? ?  input_escape(params[:pl_customer_id]).to_s.strip : ''
  dt_itemcode  =  input_escape(params[:dt_itemcode]).to_s.present? ?  input_escape(params[:dt_itemcode]).to_s.strip : ''
  dt_itemname  =  input_escape(params[:dt_itemname]).to_s.present? ?  input_escape(params[:dt_itemname]).to_s.strip : ''
  dt_pltype    =  input_escape(params[:dt_pltype]).to_s.present? ?  input_escape(params[:dt_pltype]).to_s.strip : ''
  dt_boxno     =  input_escape(params[:dt_boxno]).to_s.present? ?  input_escape(params[:dt_boxno]).to_s.strip : ''
  dt_totalpbno =  input_escape(params[:dt_totalpbno]).to_s.present? ?  input_escape(params[:dt_totalpbno]).to_s.strip : ''
  dt_pltype    =  input_escape(params[:dt_pltype]).to_s.present? ?  input_escape(params[:dt_pltype]).to_s.strip : ''
  qnty         =  input_escape(params[:dt_quantity]).to_s.present? ?  input_escape(params[:dt_quantity]).to_s.strip : ''
  dt_qty_hdr   =  input_escape(params[:dt_qty_hdr]).to_s.present? ?  input_escape(params[:dt_qty_hdr]).to_s.strip : ''
  pld_icz_descp   =  input_escape(params[:dt_pld_icz_descp]).to_s.present? ?  input_escape(params[:dt_pld_icz_descp]).to_s.strip : ''
  pld_icz_size1   =  input_escape(params[:dt_pld_icz_size1]).to_s.present? ?  input_escape(params[:dt_pld_icz_size1]).to_s.strip : 0
  pld_icz_size2   =  input_escape(params[:dt_pld_icz_size2]).to_s.present? ?  input_escape(params[:dt_pld_icz_size2]).to_s.strip : 0
  pld_icz_size3   =  input_escape(params[:dt_pld_icz_size3]).to_s.present? ?  input_escape(params[:dt_pld_icz_size3]).to_s.strip : 0
  pld_icz_size3   =  input_escape(params[:dt_pld_icz_size3]).to_s.present? ?  input_escape(params[:dt_pld_icz_size3]).to_s.strip : 0
  pld_icz_piece   =  input_escape(params[:pld_icz_piece]).to_s.present? ?  input_escape(params[:pld_icz_piece]).to_s.strip : 0
  pld_icz_cbm     =  input_escape(params[:dt_pld_icz_cbm]).to_s.present? ?  input_escape(params[:dt_pld_icz_cbm]).to_s.strip : 0
  pld_mcz_descp   =  input_escape(params[:dt_pld_mcz_descp]).to_s.present? ?  input_escape(params[:dt_pld_mcz_descp]).to_s.strip : ''
  pld_mcz_size1   =  input_escape(params[:dt_pld_mcz_size1]).to_s.present? ?  input_escape(params[:dt_pld_mcz_size1]).to_s.strip : 0
  pld_mcz_size2   =  input_escape(params[:dt_pld_mcz_size2]).to_s.present? ?  input_escape(params[:dt_pld_mcz_size2]).to_s.strip : 0
  pld_mcz_size3   =  input_escape(params[:dt_pld_mcz_size3]).to_s.present? ?  input_escape(params[:dt_pld_mcz_size3]).to_s.strip : 0
  pld_mcz_piece   =  input_escape(params[:dt_pld_mcz_piece]).to_s.present? ?  input_escape(params[:dt_pld_mcz_piece]).to_s.strip : 0
  pld_mcz_cbm     =  input_escape(params[:dt_pld_mcz_cbm]).to_s.present? ?  input_escape(params[:dt_pld_mcz_cbm]).to_s.strip : 0

  headermid    =  params[:headerid]!=nil && params[:headerid]!='' ? params[:headerid].delete(' ') : 0
  message      =  ""
  myid         = ""
  isFlags      = true
  ApplicationRecord.transaction do
  if comp_codes.to_s.blank?
      message  =  "company is required."
      isFlags  =  false
  elsif comp_type.to_s.blank?
      message =  "Type is required."
      isFlags  =  false
  elsif plnumber.to_s.blank?
      message  =  "Packing number is required."
      isFlags  =  false
  elsif pl_date.to_s.blank?
      message =  "Packing date is date"
      isFlags  =  false
  elsif buyers.to_i<=0  
    message  =  "Buyer is required."
    isFlags  =  false  
    myid     =  "customers"
  elsif dt_itemcode.to_s.blank?
    message  =  "Part no is required."
    isFlags  =  false      
    myid     = "dt_itemcode1"
  elsif dt_itemname.to_s.blank?
    message =  "Part description is required."
    isFlags       =  false   
     myid         = "itemname1"
  elsif dt_pltype.to_s.blank?  
      message =  "Pallet type is required."
      isFlags       =  false 
      myid         = "dt_pltype1"
 elsif dt_boxno.to_s.blank?  
      message =  "Box/Pallet no. is required."
      isFlags       =  false   
      myid         ="dt_boxno1"
    elsif qnty.to_s.blank?  
       message =  "Total qnty is required."
       myid    = "qnty1"
      isFlags  =  false         
  else
      #########check box digits#############
        selectedbox = ''
        cboxnopart  = dt_boxno.to_s.split("-")        
      ######check box digits ###########

     if headermid.to_i >0
        curr_boxno  = input_escape(params[:curr_boxno])
        if dt_boxno.to_s.downcase !=curr_boxno.to_s.downcase
          if cboxnopart && cboxnopart[1].to_i >0
             p1 = cboxnopart[0]
             p2 = cboxnopart[1]
            checkduplicate = TrnPackingListDetail.where("pld_compcode=? AND (FIND_IN_SET('#{p1}', pld_palletboxlist) > 0 OR FIND_IN_SET('#{p2}', pld_palletboxlist) > 0) AND pld_number =? AND UPPER(pld_boxtype) = ?",comp_codes,plnumber,dt_pltype.to_s.upcase)
          else
            checkduplicate = TrnPackingListDetail.where("pld_compcode=? AND FIND_IN_SET('#{dt_boxno}', pld_palletboxlist) > 0 AND pld_number =? AND UPPER(pld_boxtype) = ?",comp_codes,plnumber,dt_pltype.to_s.upcase)
          end
            
            if checkduplicate.length >0            
                  message =  "Duplicate Box numbers are not allowed within the same box or pallet number."
                  isFlags  =  false  
            end
        end
     end
     if isFlags
        headermid = create()
     end
  end
 

  rescue ActiveRecord::RecordNotFound => e
  # Handle the specific exception when the record is not found
  message = "Record not found "##{e.message}
  isFlags  = false 

  rescue ActiveRecord::StatementInvalid => e
    # Handle SQL syntax errors or invalid queries
    message =  "Unknown error  #{e.message}" ##{e.message}
    isFlags  = false 
  rescue StandardError => e
    # Handle any other errors
    message =  "An error occurred #{e.message}" ##{e.message}
    isFlags  = false 
  end

  footpacklist  =  TrnPackingListDetail.where("pld_compcode=? AND pld_number=? AND pld_locality_type=?",comp_codes,plnumber,comp_type).order(Arel.sql("CAST(SUBSTRING_INDEX(pld_box_no, '-', 1) AS UNSIGNED) ASC"))
  vhtml         = render_to_string :template  => 'packing_list/packing_list_views',:layout => false, :locals => { :footpacklist => footpacklist}
   respond_to do |format|
     format.json { render :json => { 'data'=>vhtml,:headermid=>headermid,:myid=>myid, "message"=>message,:status=>isFlags } }
   end

end
   
######END AJAX RULE FOR CREATE PACKING LIST ###########
  
def create
   @compcodes  =  session[:loggedUserCompCode]
   @logedId    =  session[:autherizedUserId]
   comp_codes  =  params[:hd_company].to_s.present? ? params[:hd_company].to_s.strip : @compcodes
   comp_type   =  params[:hd_type].to_s.present? ? params[:hd_type].to_s.strip : 'Local'
   isFlags     =  true
   headermid   =  params[:headerid].to_s.present? ?  params[:headerid].to_s.strip : 0
   plnumber    =  params[:pl_number].to_s.present? ? params[:pl_number].to_s.strip : 0        
  
            #packobj = TrnPackingList.where("pl_compcode=? AND pl_number=? AND pl_local_type=?",comp_codes,plnumber,comp_type)
            if  headermid.to_i >0
                   
                    upobj  = TrnPackingList.where("pl_compcode=? AND id=?",comp_codes,headermid).first                   
                    if upobj
                       pld_number = upobj.pl_number
                        upobj.update(save_pack_listing)
                        process_footer_data(pld_number)                      
                        isFlags = true
                    end
                    
            else

                  @pobj =  TrnPackingList.new(save_pack_listing)
                  if headermid.to_i >0
                        pld_number = plnumber
                    else
                        pld_number  = @sumOfCode
                    end
                    if  @pobj.save 
                        headermid = @pobj.id.to_i
                        process_footer_data(pld_number)                 
                        isFlags   = true
                        
                       
                        
                    end
            end
      return headermid
            
   
end


def process_footer_data(pld_number)
    pld_sale_type   =  'S'
    comp_codes      =  input_escape(params[:hd_company]).to_s.present? ? input_escape(params[:hd_company]) : @compcodes
    comp_type       =  input_escape(params[:hd_type]).to_s.present? ? input_escape(params[:hd_type]) :'Local'
    plnumber        =  input_escape(params[:pl_number]).to_s.present? ?  input_escape(params[:pl_number]).to_s.strip : ''
    pl_date         =  input_escape(params[:pl_date]).to_s.present? ?  input_escape(params[:pl_date]).to_s.strip : ''
    joborder        =  input_escape(params[:pld_oa_number]).to_s.present? ?  input_escape(params[:pld_oa_number]).to_s.strip : ''
    buyers          =  input_escape(params[:pl_customer_id]).to_s.present? ?  input_escape(params[:pl_customer_id]).to_s.strip : ''
    dt_itemcode     =  input_escape(params[:dt_itemcode]).to_s.present? ?  input_escape(params[:dt_itemcode]).to_s.strip : ''
    dt_itemname     =  input_escape(params[:dt_itemname]).to_s.present? ?  input_escape(params[:dt_itemname]).to_s.strip : ''
    dt_pltype       =  input_escape(params[:dt_pltype]).to_s.present? ?  input_escape(params[:dt_pltype]).to_s.strip : ''
    dt_boxno        =  input_escape(params[:dt_boxno]).to_s.present? ?  input_escape(params[:dt_boxno]).to_s.strip : ''
    dt_totalpbno    =  input_escape(params[:dt_totalpbno]).to_s.present? ?  input_escape(params[:dt_totalpbno]).to_s.strip : ''    
    qnty            =  input_escape(params[:dt_quantity]).to_s.present? ?  input_escape(params[:dt_quantity]).to_s.strip : 0
    dt_qty_hdr      =  input_escape(params[:dt_qty_hdr]).to_s.present? ?  input_escape(params[:dt_qty_hdr]).to_s.strip : ''
    dt_weight       =  input_escape(params[:dt_weight]).to_s.present? ?  input_escape(params[:dt_weight]).to_s.strip : 0
    dt_net_weight   =  input_escape(params[:dt_net_weight]).to_s.present? ?  input_escape(params[:dt_net_weight]).to_s.strip : 0
    packing_weight  =  input_escape(params[:dt_packing_weight]).to_s.present? ?  input_escape(params[:dt_packing_weight]).to_s.strip : 0
    dt_gross_weight =  input_escape(params[:dt_gross_weight]).to_s.present? ?  input_escape(params[:dt_gross_weight]).to_s.strip : 0
    pld_material    =  input_escape(params[:dt_material]).to_s.present? ?  input_escape(params[:dt_material]).to_s.strip : ''
    pld_color       =  input_escape(params[:dt_color]).to_s.present? ?  input_escape(params[:dt_color]).to_s.strip : ''
    bill_id         =   0
    dt_values       =  input_escape(params[:dt_values]).to_s.present? ?  input_escape(params[:dt_values]).to_s.strip : 0
    pld_position    =  input_escape(params[:position]).to_s.present? ?  input_escape(params[:position]).to_s.strip : 0
    removeitem      =  input_escape(params[:removeitem]).to_s.present? ?  input_escape(params[:removeitem]).to_s.strip : ''
    eid             =  input_escape(params[:eid]).to_s.present? ?  input_escape(params[:eid]).to_s.strip : 0
    pld_icz_descp             =  input_escape(params[:dt_pld_icz_descp]).to_s.present? ?  input_escape(params[:dt_pld_icz_descp]).to_s.strip : ''
    pld_icz_size1             =  input_escape(params[:dt_pld_icz_size1]).to_s.present? ?  input_escape(params[:dt_pld_icz_size1]).to_s.strip : 0
    pld_icz_size2           =  input_escape(params[:dt_pld_icz_size2]).to_s.present? ?  input_escape(params[:dt_pld_icz_size2]).to_s.strip : 0
    pld_icz_size3             =  input_escape(params[:dt_pld_icz_size3]).to_s.present? ?  input_escape(params[:dt_pld_icz_size3]).to_s.strip : 0
    pld_icz_size3             =  input_escape(params[:dt_pld_icz_size3]).to_s.present? ?  input_escape(params[:dt_pld_icz_size3]).to_s.strip : 0
    pld_icz_piece             =  input_escape(params[:pld_icz_piece]).to_s.present? ?  input_escape(params[:pld_icz_piece]).to_s.strip : 0
    pld_icz_cbm             =  input_escape(params[:dt_pld_icz_cbm]).to_s.present? ?  input_escape(params[:dt_pld_icz_cbm]).to_s.strip : 0
    pld_mcz_descp             =  input_escape(params[:dt_pld_mcz_descp]).to_s.present? ?  input_escape(params[:dt_pld_mcz_descp]).to_s.strip : ''
    pld_mcz_size1             =  input_escape(params[:dt_pld_mcz_size1]).to_s.present? ?  input_escape(params[:dt_pld_mcz_size1]).to_s.strip : 0
    pld_mcz_size2             =  input_escape(params[:dt_pld_mcz_size2]).to_s.present? ?  input_escape(params[:dt_pld_mcz_size2]).to_s.strip : 0
    pld_mcz_size3             =  input_escape(params[:dt_pld_mcz_size3]).to_s.present? ?  input_escape(params[:dt_pld_mcz_size3]).to_s.strip : 0
    pld_mcz_piece             =  input_escape(params[:dt_pld_mcz_piece]).to_s.present? ?  input_escape(params[:dt_pld_mcz_piece]).to_s.strip : 0
    pld_mcz_cbm             =  input_escape(params[:dt_pld_mcz_cbm]).to_s.present? ?  input_escape(params[:dt_pld_mcz_cbm]).to_s.strip : 0

     #########check box digits#############
     selectedbox = ''
     cboxnopart  = dt_boxno.to_s.split("-")
     if cboxnopart && cboxnopart[1].to_i >0
          p1 = cboxnopart[0]
          p2 = cboxnopart[1]
          for i in p1..p2 do
               selectedbox += i.to_s+","
          end
           
           if selectedbox.to_s.present?
                selectedbox = selectedbox.to_s.chop
           end
     else   
          selectedbox =   dt_boxno.to_s
          
     end
   ######check box digits ###########


      if dt_itemcode.to_s.present? && qnty.to_s.present?  && pld_number.to_s.present?  
        create_packlist_linking(comp_codes,comp_type,dt_itemcode,dt_itemname,plnumber,pld_sale_type,joborder,pld_material,pld_color,qnty,dt_qty_hdr,dt_boxno,dt_weight,dt_net_weight,packing_weight,dt_gross_weight,dt_values,eid,pld_position,dt_totalpbno,dt_pltype,selectedbox,pld_icz_descp,pld_icz_size1,pld_icz_size2,pld_icz_size3,pld_icz_piece,pld_icz_cbm,pld_mcz_descp,pld_mcz_size1,pld_mcz_size2,pld_mcz_size3,pld_mcz_piece,pld_mcz_cbm)
      end 
end

def delete_process_packing_list
  comp_codes   =  input_escape(params[:hd_company]).to_s.present? ? input_escape(params[:hd_company]) : @compcodes
  comp_type    =  input_escape(params[:hd_type]).to_s.present? ? input_escape(params[:hd_type]) : 'Local'
  mid          =  input_escape(params[:mid]).to_s.present? ? input_escape(params[:mid]) : 0
  plnumber     = ''
  isFlags      = true
  message      = ''
  if mid.to_i >0
       
        delobjs   = TrnPackingListDetail.where("pld_compcode=? AND id= ?",comp_codes,mid).first
        if delobjs
              plnumber    = delobjs.pld_number 
              dt_compcode = delobjs.pld_compcode.to_s
              dt_itemcode = delobjs.pld_itemcode.to_s
              dt_quantity = delobjs.pld_qty.to_i
              oano        = delobjs.pld_oa_number
              headcheck   = TrnPackingInvoice.where("pli_compcode=? AND pli_packlist_no=?",dt_compcode,plnumber)
              if headcheck.length >0
                    message  =  "Could not be deleted due to used in export invoice."
                    isFlags  =  false 
              else
                    reverse_mis_detail(dt_compcode,dt_itemcode,oano,0,0,0,dt_quantity,0)
                    if delobjs.destroy
                        message  =  "Data deleted sucessfully."
                        isFlags  =  true               
                    else
                        message  =  "Unable to delete."
                        isFlags  =  false 
                    end
            end
            
        end
  else
        message =  "mis-match entered detail."
        isFlags  =  false  
 end

 footpacklist  =  TrnPackingListDetail.where("pld_compcode=? AND pld_number=? AND pld_locality_type=?",comp_codes,plnumber,comp_type).order(Arel.sql("CAST(SUBSTRING_INDEX(pld_box_no, '-', 1) AS UNSIGNED) ASC"))
 vhtml         = render_to_string :template  => 'packing_list/packing_list_views',:layout => false, :locals => { :footpacklist => footpacklist}
  respond_to do |format|
    format.json { render :json => { 'data'=>vhtml, "message"=>message,:status=>isFlags } }
  end

end

def update_header_footer_detais
  comp_codes         =  input_escape(params[:hd_company]).to_s.present? ? input_escape(params[:hd_company]) : @compcodes
  mid                =  input_escape(params[:myheaderid]).to_s.present? ? input_escape(params[:myheaderid]) : 0
  pl_totno_pices     =  input_escape(params[:pl_totno_pices]).to_s.present? ? input_escape(params[:pl_totno_pices]) : 0
  pl_totno_boxno     =  input_escape(params[:pl_totno_boxno]).to_s.present? ? input_escape(params[:pl_totno_boxno]) : 0
  pl_totno_pallet    =  input_escape(params[:pl_totno_pallet]).to_s.present? ? input_escape(params[:pl_totno_pallet]) : 0
  pl_tot_netweight   =  input_escape(params[:pl_tot_netweight]).to_s.present? ? input_escape(params[:pl_tot_netweight]) : 0
  pl_tot_grossweight =  input_escape(params[:pl_tot_grossweight]).to_s.present? ? input_escape(params[:pl_tot_grossweight]) : 0
  pl_apprx_value     =  input_escape(params[:pl_apprx_value]).to_s.present? ? input_escape(params[:pl_apprx_value]) : 0
  pl_tot_perkg       =  input_escape(params[:pl_tot_perkg]).to_s.present? ? input_escape(params[:pl_tot_perkg]) : 0
  upobj  = TrnPackingList.where("pl_compcode=? AND id=?",comp_codes,mid).first                   
  if upobj      
      upobj.update(:pl_totno_pices=>pl_totno_pices,
        :pl_totno_boxno=>pl_totno_boxno,
        :pl_totno_pallet=>pl_totno_pallet,
        :pl_tot_netweight=>pl_tot_netweight,
        :pl_tot_grossweight=>pl_tot_grossweight,
        :pl_apprx_value=>pl_apprx_value,
        :pl_tot_perkg=>pl_tot_perkg
      )                 
     
  end
  respond_to do |format|
    format.json { render :json => { :status=>isFlags } }
  end

end

def show
  @compcodes    = session[:loggedUserCompCode]
  @rootUrl      = "#{root_url}"
  @compDetail   = MstCompany.where(["cmp_companycode = ?", @compcodes]).first
   @isXProd     = get_print_selected_product()
   arr          = []
   @isPran      = MstPrnquoation.all
   if @isXProd.length >0
     @isXProd.each do |itms|
       arr.push itms
     end
     isconts = @isXProd.length
     fcont   = 12-isconts
     for i in 1..fcont
           @isPran.each do |pcx|
           arr.push pcx
          end
     end
     @isXProd = arr
   end

   if @isXProd.length >0
           respond_to do |format|
              format.pdf do
               pdf = QuotationPdf.new(@isXProd,@isCustState,@isShipto,@compDetail,@cstType,@rootUrl,@isProforma,@isTakeTax,@isGstNumbers,'','')
               #line_items
               send_data pdf.render,:filename => "1_"+params[:bill_number].to_s+"_packinglist_report.pdf", :type => "application/pdf", :disposition => "inline"
            end
         end
   end
end

def cancel
        @compcodes    =  session[:loggedUserCompCode]
       isbillnumber   =  params[:id].to_s
       localtype      =  params[:lid].to_s
       if check_existing_record(@compcodes,isbillnumber,localtype)
            flash[:error]            = "Sorry!! Unable to cancel due to somewhere used."
            flash[:notice]           = ''
            session[:isErrorhandled] = 1
       else

       packobj        = TrnPackingList.where("pl_compcode = ? AND pl_number = ? AND pl_local_type=?",@compcodes,isbillnumber,localtype).first
       if packobj         
              isstatus = packobj.pl_status
              if isstatus !='C'
                 isobjupdate = TrnPackingListDetail.where("pld_compcode=? AND pld_number= ? AND pld_locality_type=? ",@compcodes,isbillnumber,localtype)
                 ###################################
                  if isobjupdate
                      isobjupdate.each do |invs|
                        dt_compcode = invs.pld_compcode.to_s
                        dt_itemcode = invs.pld_itemcode.to_s
                        dt_quantity = invs.pld_qty.to_i
                        oano        = invs.pld_oa_number
                        reverse_mis_detail(dt_compcode,dt_itemcode,oano,0,0,0,dt_quantity,0)
                      end
                   
                  end
                  if packobj.update(:pl_status=>'C')
                      flash[:error]            = "Data cancelled successfully."
                      flash[:notice]           = ''
                      session[:isErrorhandled] = nil
                      session[:postedpamams]   = nil
                      session.delete(:postedpamams)
                      session[:isErrorhandled] = nil
                      ################################
                      session[:isErrorhandled]= nil
                      session[:postedpamams]  = nil
                  end

              else
                      flash[:error]            = "This is already cancelled."
                      flash[:notice]           = ''
                      session[:isErrorhandled] = 1
              end
         
            end
    end
    redirect_to "#{root_url}"+"packing_list"
end



def packing_list_refresh 
 session[:postedpamams]    = nil
 session[:isErrorhandled]  = nil
 session[:hd_billdate]     = nil
 session[:hd_invoiceto]    = nil
 session[:hd_customer_id]  = nil
 session[:hd_refnumber]    = nil
 session[:hd_refnumber]    = nil
 session.delete(:isErrorhandled)
 session.delete(:postedpamams)
 redirect_to "#{root_url}"+"packing_list"
end

private
def get_orderno_details
  comp_codes  = params[:comp_codes]!=nil && params[:comp_codes]!='' ? params[:comp_codes] : ''
  if  params[:hd_type]!=nil && params[:hd_type]!= '' && params[:hd_type] == 'Export'
     if comp_codes == nil ||  comp_codes == ''
       comp_codes = @compcodes
     end
  end
 objitem =  TrnProformaHdr.select("hd_billnumber").where(["hd_compcode = ? AND hd_sale_type= ? AND hd_loc = ? AND hd_type=?", comp_codes,params[:hd_sale_type].to_s,@isLoc.to_s,params[:hd_type]]).order('hd_billnumber desc')
 return objitem
end

private
def get_last_pack_number 
  comp_codes  = params[:comp_codes]!=nil && params[:comp_codes]!='' ? params[:comp_codes] : ''
  if comp_codes == nil ||  comp_codes == ''
       comp_codes = @compcodes
  end
  @isCode    = 0
  @Startx    = '0000'
  @recCodes  = TrnPackingList.where(["pl_compcode = ? AND pl_number >0 AND pl_local_type=?", comp_codes,params[:hd_type]]).order('pl_number DESC').first
  if @recCodes
   @isCode  = @recCodes.pl_number.to_i
  end
    @sumXOfCode    = @isCode.to_i + 1
    if @sumXOfCode.to_i < 10
      @sumXOfCode = p @Startx.to_s + @sumXOfCode.to_s
    elsif @sumXOfCode.to_s.length < 3
      @sumXOfCode = p "000" + @sumXOfCode.to_s
    elsif @sumXOfCode.to_s.length < 4
      @sumXOfCode = p "00" + @sumXOfCode.to_s
    elsif @sumXOfCode.to_s.length < 5
      @sumXOfCode = p "0" + @sumXOfCode.to_s
    elsif @sumXOfCode.to_s.length >5
      @sumXOfCode =  @sumXOfCode.to_i
    end
end

private
def get_last_order_details
   compname               = params[:compname]!='' && params[:compname]!=nil ? params[:compname] : ''
   xtype                  = params[:xtype]!='' && params[:xtype]!=nil ? params[:xtype] : ''
   params[:hd_type]       = xtype
   params[:hd_sale_type]  = 'S'
   params[:comp_codes]    = compname
   isstatus               = false;
   get_last_pack_number
   alloano     = [] #get_proforma_all_bills()
   allob       = []
   lastbillno  = ''

   if @sumXOfCode
       lastbillno = @sumXOfCode
       isstatus   = true
       allob     =  get_packlist_all_number()
   end

  respond_to do |format|
    format.json { render :json => { 'data'=>allob,"lastbillno"=>lastbillno,"alloano"=>alloano,"message"=>'',:status=>isstatus } }
  end

end

private
def get_proforma_all_bills 
  comp_codes  = params[:comp_codes]!=nil && params[:comp_codes]!='' ? params[:comp_codes] : ''
  if  params[:hd_type]!=nil && params[:hd_type]!= '' && params[:hd_type] == 'Local'
     if comp_codes == nil ||  comp_codes == ''
       comp_codes = @compcodes
     end
  end
 objitem =  TrnProformaHdr.select("hd_billnumber").where(["hd_compcode = ? AND hd_sale_type= ? AND hd_loc = ? AND hd_type=?", comp_codes,params[:hd_sale_type].to_s,@isLoc.to_s,params[:hd_type]]).order('hd_billnumber desc')
 return objitem
end

def get_packlist_all_bills  
  comp_codes  = params[:comp_codes]!=nil && params[:comp_codes]!='' ? params[:comp_codes] : ''
  if  params[:hd_type]!=nil && params[:hd_type]!= '' && params[:hd_type] == 'Export'
     if comp_codes == nil ||  comp_codes == ''
       comp_codes = @compcodes
     end
  end
 objitem =  TrnPackingList.select("pl_number,id,pl_compcode,pl_local_type").where(["pl_compcode = ? AND pl_sale_type=? AND pl_local_type=?", comp_codes,params[:hd_sale_type],params[:hd_type]]).order('pl_number desc')
 return objitem
end


def get_all_po_no_agaist_jono(compcode,jono,type)  
 objitem =  TrnProformaHdr.select("hd_po_number").where(["hd_compcode = ? AND hd_billnumber =? AND hd_type =?", compcode,jono,type]).first
 return objitem
end


private
def get_packlist_all_number 
   comp_codes  = params[:comp_codes]!=nil && params[:comp_codes]!='' ? params[:comp_codes] : ''
   if  params[:hd_type]!=nil && params[:hd_type]!= '' && params[:hd_type] == 'Local'
       if comp_codes == nil ||  comp_codes == ''
         comp_codes = @compcodes
       end
   end
   arr     = []
   objitem =  TrnPackingList.select("pl_number,'' as newpl_number,pl_local_type,id").where(["pl_compcode = ? AND pl_sale_type= ? AND pl_local_type=?", comp_codes,params[:hd_sale_type],params[:hd_type]]).order('pl_number DESC')
  if objitem.length >0
      objitem.each do |plsd|
        plsd.newpl_number = Base64.encode64(plsd.pl_number+"_"+comp_codes.to_s+"_"+ plsd.pl_local_type.to_s)
        arr.push plsd
      end
      
  end

  return arr
end

private
def get_customer_details()
   compname    = params[:compname]!='' && params[:compname]!=nil ? params[:compname] : ''
   xtype       = params[:xtype]!='' && params[:xtype]!=nil ? params[:xtype] : ''
   oanumber    = params[:oanumber]!='' && params[:oanumber]!=nil ? params[:oanumber] : ''
  #jons          = " JOIN mst_customers cst ON(cst.id=hd_customer_id AND cst.cs_compcode=hd_compcode)"
  obj    = TrnProformaHdr.select("hd_invoiceto,hd_dispmode,hd_billnumber,hd_po_number").where("hd_compcode=? and hd_billnumber=? and hd_type=?",compname,oanumber,xtype).first
  respond_to do |format|
    format.json { render :json => { 'data'=>obj,"message"=>'',:status=>true } }
  end

end ## END IF

private
def get_search_prdname_by_oano
    compname     = params[:compname]!='' && params[:compname]!=nil ? params[:compname] : @compcodes
    xtype        = params[:xtype]!='' && params[:xtype]!=nil ? params[:xtype] : 'Local'
    oanumber     = params[:oanumber]!='' && params[:oanumber]!=nil ? params[:oanumber] : ''
    customer     = params[:iscustomerId]!='' && params[:iscustomerId]!=nil ? params[:iscustomerId] : 0
    withjo       = params[:myjoallowed]!='' && params[:myjoallowed]!=nil ? params[:myjoallowed] : 'N'
    packingno    = params[:packingno] != '' && params[:packingno] != nil ? params[:packingno] : ''
    checkinvs    = params[:chkInvoiceType] !='' && params[:chkInvoiceType] !=nil  ? params[:chkInvoiceType] : ''
    isupdates    = params[:isupdates] !='' && params[:isupdates] !=nil  ? params[:isupdates] : ''
    selection    = params[:selection] !='' && params[:selection] !=nil  ? params[:selection] : ''
    isprodname   = nil
    myflags = false
    arrp         = []
    if withjo == 'NPPSY'
       #   iswhere     = "hd_compcode = '#{compname}' AND ( dt_closestatus<>'Y' )" # AND  dt_quantity>dt_mipackqty UMESH
          if xtype!=nil && xtype!=''
       #      iswhere  += " AND hd_type ='#{xtype}'"
          end
          if oanumber!=nil && oanumber!=''
        #   iswhere  += " AND hd_billnumber='#{oanumber}'"
         end

       #    if params[:productname]!='' && params[:productname]!=nil
       #     productname = "%"+params[:productname].to_s+"%"
       #     iswhere     += " AND dt_itemname LIKE '#{productname}'"
       #   end
       #     iswhere      += " AND hd_customer_id='#{customer}' "
       #     isselect     = " tds.*,hd_type,hd_billnumber,hd_invoiceto,hd_dispmode,'' as dtweight,'' as netweight"
       #     jons         = " JOIN trn_proforma_details tds ON(dt_compcode=hd_compcode AND hd_billnumber=dt_billnumber AND dt_sale_type=hd_sale_type)"
       #    isprodname   = TrnProformaHdr.select(isselect).joins(jons).where(iswhere).group('TRIM(dt_itemname)').order('TRIM(dt_itemname) ASC')
    end
        iswhere     = "hd_compcode = '#{compname}' AND dt_closestatus<>'Y' AND hd_customer_id ='#{customer}'"
        
         #if params[:productname]!='' && params[:productname]!=nil
          #  productname = "%"+params[:productname].to_s+"%"
          #  iswhere     += " AND pd_productname LIKE '#{productname}'"
         #end         
      #   isselect     = " '' as netweight,pd_compcode as dt_compcode,'' as hd_type,'' as hd_billnumber,'' as hd_invoiceto,'' as hd_dispmode,'' as dtweight,'' as dt_color"
      #   isselect     += " ,pd_productname as dt_itemname,pd_productcode as dt_itemcode,'' as dt_netamount,'' as dt_quantity,'' as dt_material"
      #   isprodname   = MstProduct.select(isselect).where(iswhere).group('pd_productname').order('pd_productname ASC').limit(30)
      if( selection.to_i == 1)
            if params[:productname]!='' && params[:productname]!=nil
              iswhere     += " AND UPPER(dt_itemcode)=UPPER('#{params[:productname]}')  "
            end
      else
        if params[:productname]!='' && params[:productname]!=nil
            productname = "%"+params[:productname].to_s+"%"
            iswhere     += " AND ( dt_itemname LIKE '#{productname}' ) "
         end
      end
        
        isselect     = " tds.*,hd_type,hd_billnumber,hd_invoiceto,hd_dispmode,'' as dtweight,'' as netweight"
        isselect     += ",(CASE WHEN SUM(dt_mrnqty) >SUM(dt_quantity) THEN (SUM(dt_mrnqty)-SUM(dt_mipackqty)) ELSE (SUM(dt_quantity)-SUM(dt_mipackqty)) END) as balqty"
        jons         = " JOIN trn_proforma_details tds ON(dt_compcode=hd_compcode AND hd_billnumber=dt_billnumber AND dt_sale_type=hd_sale_type)"
        
        if checkinvs == 'packlist' && isupdates == 'Y'
          isprodname   = TrnProformaHdr.select(isselect).joins(jons).where(iswhere).group('dt_itemcode,dt_billnumber').having("SUM(dt_quantity) >0").order('TRIM(dt_itemname) ASC,dt_billnumber ASC')
        else
          isprodname   = TrnProformaHdr.select(isselect).joins(jons).where(iswhere).group('dt_itemcode,dt_billnumber').having("balqty >0").order('TRIM(dt_itemname) ASC,dt_billnumber ASC')
        end
        
       
      if isprodname!=nil && isprodname.length >0
           myflags = true
            isprodname.each do |arp|
              compcode = arp.dt_compcode
              pdcode   = arp.dt_itemcode
              prdobj   = get_name_of_product(compcode,pdcode)
               if prdobj
                  arp.dtweight   = prdobj.pd_weight
                  arp.netweight  = prdobj.pd_gross_weight
               end
              arrp.push arp
            end
             msg = "success"
            
      end
      if( !myflags)
          msg = "No record(s) found."
      end
       respond_to do |format|
        format.json { render :json => { 'data'=>arrp, "message"=>msg,:status=>myflags } }
       end
end

private
def set_pallet_box_detail
    box                       = params[:box_pallet_type]!=nil && params[:box_pallet_type]!='' ? params[:box_pallet_type] : 'B'
    session[:box_pallet_type] = box
    respond_to do |format|
      format.json { render :json => { 'data'=>'', "message"=>'',:status=>true } }
     end
end
def check_print_pallet
  pallet_dt           = params[:pallettype]!=nil && params[:pallettype]!='' ? params[:pallettype] : ''
  session[:pallet_dt] = pallet_dt
  respond_to do |format|
    format.json { render :json => { 'data'=>'', "message"=>'',:status=>true } }
   end

end

private
def get_search_by_joborders
    compname    = params[:compname]!='' && params[:compname]!=nil ? params[:compname] : @compcodes
    xtype       = params[:xtype]!='' && params[:xtype]!=nil ? params[:xtype] : 'Local'
    customers   = params[:customers]!='' && params[:customers]!=nil ? params[:customers] : 0
    msg         = ""
    iswhere     = "hd_compcode = '#{compname}' AND ( dt_closestatus<>'Y' )" #AND  dt_quantity>dt_mipackqty UMESH
      if xtype!=nil && xtype!=''
         iswhere  += " AND hd_type ='#{xtype}'"
      end
     if params[:productname]!='' && params[:productname]!=nil
        productname = "%"+params[:productname].to_s+"%"
        iswhere     += " AND hd_billnumber LIKE '#{productname}'"
     end 
     if customers.to_i >0      
        iswhere   += " AND hd_customer_id ='#{customers}'"
     end 
     isselect     = " tds.*,hd_type,hd_billnumber,hd_invoiceto,hd_dispmode,'' as dtweight"
     jons         = " JOIN trn_proforma_details tds ON(dt_compcode=hd_compcode AND hd_billnumber=dt_billnumber AND dt_sale_type=hd_sale_type)"
     isprodname   = TrnProformaHdr.select(isselect).joins(jons).where(iswhere).group('TRIM(hd_billnumber)').order('TRIM(hd_billnumber) ASC')
     arrp         = []
    if isprodname.length >0
          isprodname.each do |arp|
            compcode = arp.dt_compcode
            pdcode   = arp.dt_itemcode
            prdobj   = get_name_of_product(compcode,pdcode)
             if prdobj
                arp.dtweight  = prdobj.pd_weight
             end
            arrp.push arp
          end
           msg = "success"
           
    end
    respond_to do |format|
    format.json { render :json => { 'data'=>arrp, "message"=>msg,:status=>true } }
   end
   
end



private
def save_pack_listing
   comp_codes  =  params[:hd_company]!=nil && params[:hd_company]!='' ? params[:hd_company] : @compcodes
   comp_type   =  params[:hd_type]!=nil && params[:hd_type]!='' ? params[:hd_type] : 'Local'
   headermid   =  params[:headerid].to_s.present? ?  params[:headerid].to_s.strip : 0
   @isCode     =  0
   @Startx     = '0000'
   @recCodes   = TrnPackingList.select("pl_number").where(["pl_compcode = ? AND  pl_sale_type=? AND pl_number >0 AND pl_local_type=?", comp_codes,params[:hd_sale_type],comp_type]).order('pl_number DESC').first
   if @recCodes
      @isCode    = @recCodes.pl_number.to_i
   end
    @sumOfCode    = @isCode.to_i + 1
    if @sumOfCode.to_i < 10
      @sumOfCode = p @Startx.to_s + @sumOfCode.to_s
    elsif @sumOfCode.to_s.length < 3
      @sumOfCode = p "000" + @sumOfCode.to_s
    elsif @sumOfCode.to_s.length < 4
      @sumOfCode = p "00" + @sumOfCode.to_s
    elsif @sumOfCode.to_s.length < 5
      @sumOfCode = p "0" + @sumOfCode.to_s
    elsif @sumOfCode.to_s.length >5
      @sumOfCode =  @sumOfCode.to_i
    end
    if headermid.to_i >0
		    params[:pl_number] = params[:pl_number]
	   else
		     params[:pl_number] = @sumOfCode
	  end
   params[:pl_sale_type]        =  params[:hd_sale_type]!=nil && params[:hd_sale_type]!='' ? params[:hd_sale_type] : 'S'
   params[:pl_oa_number]        =  params[:pl_oa_number]!=nil && params[:pl_oa_number]!='' ? params[:pl_oa_number] : ''   
   params[:pl_totno_pices]      =  params[:pl_totno_pices]!=nil && params[:pl_totno_pices]!='' ? params[:pl_totno_pices] : 0
   params[:pl_totno_boxno]      =  params[:pl_totno_boxno]!=nil && params[:pl_totno_boxno]!='' ? params[:pl_totno_boxno] : 0
   params[:pl_tot_netweight]    =  params[:pl_tot_netweight]!=nil && params[:pl_tot_netweight]!='' ? params[:pl_tot_netweight] : 0
   params[:pl_apprx_value]      =  params[:pl_apprx_value]!=nil && params[:pl_apprx_value]!='' ? params[:pl_apprx_value] : 0
   params[:pl_tot_grossweight]  =  params[:pl_tot_grossweight]!=nil && params[:pl_tot_grossweight]!='' ? params[:pl_tot_grossweight] : 0
   params[:pl_tot_perkg]        =  params[:pl_tot_perkg]!=nil && params[:pl_tot_perkg]!='' ? params[:pl_tot_perkg] : 0
   params[:pl_totno_pallet]     =  params[:pl_totno_pallet]!=nil && params[:pl_totno_pallet]!='' ? params[:pl_totno_pallet] : 0
   params[:pl_customer_id]      =  params[:pl_customer_id]!=nil && params[:pl_customer_id]!='' ? params[:pl_customer_id] : 0
   params[:pl_customername]     =  params[:pl_customername]!=nil && params[:pl_customername]!='' ? params[:pl_customername] : 0
   dt = 0
  if  params[:pl_date]!=nil  && params[:pl_date]!=''
      ndt = Date.parse(params[:pl_date].to_s)
      dt  = ndt.strftime("%Y-%m-%d")
  end
   params[:pl_compcode]   = comp_codes
   params[:pl_local_type] = comp_type
   params[:pl_date]       = dt   
   params.permit(:pl_compcode,:pl_totno_pallet,:pl_customer_id,:pl_customername,:pl_number,:pl_date,:pl_sale_type,:pl_local_type,:pl_oa_number,:pl_totno_pices,:pl_totno_boxno,:pl_tot_netweight,:pl_tot_grossweight,:pl_apprx_value,:pl_tot_perkg)
end


private
def create_packlist_linking(comp_codes,comp_type,pld_itemcode,pld_itemname,pld_number,pld_sale_type,pld_oa_number,pld_material,pld_color,pld_qty,pld_outer_qty,pld_box_no,pld_weight,pld_net_weight,pld_pck_weight,pld_gross_weight,pld_netvalues,bill_id,pld_position,pld_palletboxes,pld_boxtype,boxlist='',pld_icz_descp,pld_icz_size1,pld_icz_size2,pld_icz_size3,pld_icz_piece,pld_icz_cbm,pld_mcz_descp,pld_mcz_size1,pld_mcz_size2,pld_mcz_size3,pld_mcz_piece,pld_mcz_cbm)
    
    if bill_id.to_i >0
          isobjupdate = TrnPackingListDetail.where("pld_compcode=? AND id= ? ",comp_codes,bill_id).first
          if isobjupdate
             oldqty     = isobjupdate.pld_qty
             isobjupdate.update(:pld_compcode=>comp_codes,:pld_palletboxlist=>boxlist,:pld_palletboxes=>pld_palletboxes,:pld_boxtype=>pld_boxtype,:pld_position=>pld_position,:pld_locality_type=>comp_type,:pld_itemcode=>pld_itemcode,:pld_itemname=>pld_itemname,:pld_number=>pld_number,:pld_sale_type=>pld_sale_type,:pld_oa_number=>pld_oa_number,:pld_material=>pld_material,:pld_color=>pld_color,:pld_qty=>pld_qty,:pld_outer_qty=>pld_outer_qty,:pld_box_no=>pld_box_no,:pld_weight=>pld_weight,:pld_net_weight=>pld_net_weight,:pld_pck_weight=>pld_pck_weight,:pld_gross_weight=>pld_gross_weight,:pld_netvalues=>pld_netvalues,:pld_icz_descp=>pld_icz_descp,:pld_icz_size1=>pld_icz_size1,:pld_icz_size2=>pld_icz_size2,:pld_icz_size3=>pld_icz_size3,:pld_icz_piece=>pld_icz_piece,:pld_icz_cbm=>pld_icz_cbm,:pld_mcz_descp=>pld_mcz_descp,:pld_mcz_size1=>pld_mcz_size1,:pld_mcz_size2=>pld_mcz_size2,:pld_mcz_size3=>pld_mcz_size3,:pld_mcz_piece=>pld_mcz_piece,:pld_mcz_cbm=>pld_mcz_cbm)
             ## execute message if required
             reverse_mis_detail(comp_codes,pld_itemcode,pld_oa_number,0,0,0,oldqty,0)
             set_mis_detail(comp_codes,pld_itemcode,pld_oa_number,0,0,0,pld_qty,0)
          end
    else
          nobsave =   TrnPackingListDetail.new(:pld_compcode=>comp_codes,:pld_palletboxlist=>boxlist,:pld_palletboxes=>pld_palletboxes,:pld_boxtype=>pld_boxtype,:pld_position=>pld_position,:pld_locality_type=>comp_type,:pld_itemcode=>pld_itemcode,:pld_itemname=>pld_itemname,:pld_number=>pld_number,:pld_sale_type=>pld_sale_type,:pld_oa_number=>pld_oa_number,:pld_material=>pld_material,:pld_color=>pld_color,:pld_qty=>pld_qty,:pld_outer_qty=>pld_outer_qty,:pld_box_no=>pld_box_no,:pld_weight=>pld_weight,:pld_net_weight=>pld_net_weight,:pld_pck_weight=>pld_pck_weight,:pld_gross_weight=>pld_gross_weight,:pld_netvalues=>pld_netvalues,:pld_icz_descp=>pld_icz_descp,:pld_icz_size1=>pld_icz_size1,:pld_icz_size2=>pld_icz_size2,:pld_icz_size3=>pld_icz_size3,:pld_icz_piece=>pld_icz_piece,:pld_icz_cbm=>pld_icz_cbm,:pld_mcz_descp=>pld_mcz_descp,:pld_mcz_size1=>pld_mcz_size1,:pld_mcz_size2=>pld_mcz_size2,:pld_mcz_size3=>pld_mcz_size3,:pld_mcz_piece=>pld_mcz_piece,:pld_mcz_cbm=>pld_mcz_cbm)
          if nobsave.save
            ## execute message if required
            set_mis_detail(comp_codes,pld_itemcode,pld_oa_number,0,0,0,pld_qty,0)
          end
    end
end

private
def pack_delete_item(comp_codes,bill_id)
    isobjupdate = TrnPackingListDetail.where("pld_compcode=? AND id= ? ",comp_codes,bill_id).first
    if isobjupdate
      pld_itemcode   = isobjupdate.pld_itemcode
      oldqty         = isobjupdate.pld_qty
      pld_oa_number  = isobjupdate.pld_oa_number
      reverse_mis_detail(comp_codes,pld_itemcode,pld_oa_number,0,0,0,oldqty,0)
      isobjupdate.destroy
    end
end

private
def rollback_billing_if_not_acl(billnumber)
      ompcodes    =  params[:hd_company]!=nil && params[:hd_company]!='' ? params[:hd_company] : @compcodes
      hdtype      =  params[:hd_type]!=nil && params[:hd_type]!='' ? params[:hd_type] : ''
      @chkObj     =  TrnPackingList.joins('INNER JOIN trn_packing_list_details trn ON(pld_compcode=pl_compcode AND pld_sale_type=pl_sale_type AND pld_number=pl_number AND pld_locality_type=pl_local_type)').where("pl_compcode = ? AND pl_number=? AND pl_sale_type= ? AND pl_local_type=?",ompcodes,billnumber,params[:hd_sale_type],hdtype)
      if @chkObj.length <= 0
          @delObj =  TrnPackingList.where("pl_compcode = ? AND pl_number=? AND pl_sale_type= ? AND pl_local_type=?",ompcodes,billnumber,params[:hd_sale_type],hdtype).first
          if @delObj
            @delObj.destroy
          end
      end

end


private
  def check_existing_record(compcode,packingno,typecode)
      status     =  false      
      packingobj =  TrnPackingInvoice.where("pli_compcode =? AND pli_packlist_no = ? AND pli_local_type = ? AND pli_status<>'C'",compcode,packingno,typecode)
      if packingobj.length >0
          status = true         
      end   

      return status
  end
  private
  def get_joborder_oem_detail(itemcode,jono="")
   compcodes  = session[:loggedUserCompCode]
   iswhere    = "dt_compcode='#{compcodes}' AND dt_itemcode='#{itemcode}' "
   if jono.to_s.present?
      iswhere    +=" AND dt_billnumber='#{jono}' "  
   end
   checkjob   =  TrnProformaDetail.where(iswhere).order("dt_itemcode ASC").first
   return checkjob
 
  end

  
  private
  def process_grid_data(pld_number)
     comp_codes      =  params[:hd_company]!=nil && params[:hd_company]!='' ? params[:hd_company] : @compcodes
     comp_type       =  params[:hd_type]!=nil && params[:hd_type]!='' ? params[:hd_type] : 'Local'
     pld_sale_type   =  params[:hd_sale_type]!=nil && params[:hd_sale_type]!='' ? params[:hd_sale_type] : 'S'
     
     if params[:removeitem]!='' && params[:removeitem]!=nil
        j = 0
        params[:removeitem].each do |tnd|
               if params[:removeitem][j]!=nil && params[:removeitem][j]!=''
                  billid = params[:removeitem][j]
               else
                  billid = 0
              end
              if billid.to_i >0
                  pack_delete_item(comp_codes,billid)
              end
            j += 1
        end
        
    end
    
    
    if params[:dt_itemcode]!='' && params[:dt_itemcode]!=nil
        i = 0
        params[:dt_itemcode].each do |tnd|
          
              if params[:pld_oa_number][i]!=nil && params[:pld_oa_number][i]!=''
                 pld_oa_number = params[:pld_oa_number][i]
              else
                 pld_oa_number = ''
              end
              if params[:dt_itemcode][i]!=nil && params[:dt_itemcode][i]!=''
                 pld_itemcode = params[:dt_itemcode][i]
              else
                 pld_itemcode = ''
              end
              if params[:dt_itemname][i]!=nil && params[:dt_itemname][i]!=''
                 pld_itemname = params[:dt_itemname][i]
              else
                 pld_itemname = ''
              end
              if params[:dt_quantity][i]!=nil && params[:dt_quantity][i]!=''
                 pld_qty = params[:dt_quantity][i]
              else
                 pld_qty = 0
              end
              if params[:bill_id][i]!=nil && params[:bill_id][i]!=''
                 bill_id = params[:bill_id][i]
              else
                 bill_id = 0
              end
              if params[:dt_material][i]!=nil && params[:dt_material][i]!=''
                 pld_material = params[:dt_material][i]
              else
                 pld_material = ''
              end
              if params[:dt_color][i]!=nil && params[:dt_color][i]!=''
                 pld_color = params[:dt_color][i]
              else
                 pld_color = ''
              end
              if params[:dt_boxno][i]!=nil && params[:dt_boxno][i]!=''
                 pld_box_no = params[:dt_boxno][i]
              else
                 pld_box_no = 0
              end
              if params[:dt_qty_hdr][i]!=nil && params[:dt_qty_hdr][i]!=''
                 pld_outer_qty = params[:dt_qty_hdr][i]
              else
                 pld_outer_qty = 0
              end
              if params[:dt_weight][i]!=nil && params[:dt_weight][i]!=''
                 pld_weight = params[:dt_weight][i]
              else
                 pld_weight = 0
              end
              if params[:dt_net_weight][i]!=nil && params[:dt_net_weight][i]!=''
                 pld_net_weight = params[:dt_net_weight][i]
              else
                 pld_net_weight = 0
              end
              if params[:dt_packing_weight][i]!=nil && params[:dt_packing_weight][i]!=''
                 pld_pck_weight = params[:dt_packing_weight][i]
              else
                 pld_pck_weight = 0
              end
              if params[:dt_gross_weight][i]!=nil && params[:dt_gross_weight][i]!=''
                 pld_gross_weight = params[:dt_gross_weight][i]
              else
                 pld_gross_weight = 0
              end
              if params[:dt_values][i]!=nil && params[:dt_values][i]!=''
                 pld_netvalues = params[:dt_values][i]
              else
                 pld_netvalues = 0
              end
              if params[:pld_position][i]!=nil && params[:pld_position][i]!=''
                pld_position = params[:pld_position][i]
              else
                pld_position = 0
              end
              
              if params[:dt_totalpbno][i]!=nil && params[:dt_totalpbno][i]!=''
                pld_palletboxes = params[:dt_totalpbno][i]
              else
                pld_palletboxes = 0
              end
              if params[:dt_pltype][i]!=nil && params[:dt_pltype][i]!=''
                pld_boxtype = params[:dt_pltype][i]
              else
                pld_boxtype = 0
              end
              if params[:dt_pld_icz_descp][i]!=nil && params[:dt_pld_icz_descp][i]!=''
                pld_icz_descp = params[:dt_pld_icz_descp][i]
              else
                pld_icz_descp = ''
              end
              if params[:dt_pld_icz_size1][i]!=nil && params[:dt_pld_icz_size1][i]!=''
                pld_icz_size1 = params[:dt_pld_icz_size1][i]
              else
                pld_icz_size1 = ''
              end
              if params[:dt_pld_icz_size2][i]!=nil && params[:dt_pld_icz_size2][i]!=''
                pld_icz_size2 = params[:dt_pld_icz_size2][i]
              else
                pld_icz_size2 = ''
              end
              if params[:dt_pld_icz_size3][i]!=nil && params[:dt_pld_icz_size3][i]!=''
                pld_icz_size3 = params[:dt_pld_icz_size3][i]
              else
                pld_icz_size3 = ''
              end
              if params[:dt_pld_icz_piece][i]!=nil && params[:dt_pld_icz_piece][i]!=''
                pld_icz_piece = params[:dt_pld_icz_piece][i]
              else
                pld_icz_piece = ''
              end
              if params[:dt_pld_icz_cbm][i]!=nil && params[:dt_pld_icz_cbm][i]!=''
                pld_icz_cbm = params[:dt_pld_icz_cbm][i]
              else
                pld_icz_cbm = ''
              end
              if params[:dt_pld_mcz_descp][i]!=nil && params[:dt_pld_mcz_descp][i]!=''
                pld_mcz_descp = params[:dt_pld_mcz_descp][i]
              else
                pld_mcz_descp = ''
              end
              if params[:dt_pld_mcz_size1][i]!=nil && params[:dt_pld_mcz_size1][i]!=''
                pld_mcz_size1 = params[:dt_pld_mcz_size1][i]
              else
                pld_mcz_size1 = ''
              end
              if params[:dt_pld_mcz_size2][i]!=nil && params[:dt_pld_mcz_size2][i]!=''
                pld_mcz_size2 = params[:dt_pld_mcz_size2][i]
              else
                pld_mcz_size2 = ''
              end
              if params[:dt_pld_mcz_size3][i]!=nil && params[:dt_pld_mcz_size3][i]!=''
                pld_mcz_size3 = params[:dt_pld_mcz_size3][i]
              else
                pld_mcz_size3 = ''
              end
              if params[:dt_pld_mcz_piece][i]!=nil && params[:dt_pld_mcz_piece][i]!=''
                pld_mcz_piece = params[:dt_pld_mcz_piece][i]
              else
                pld_mcz_piece = ''
              end
              if params[:dt_pld_mcz_cbm][i]!=nil && params[:dt_pld_mcz_cbm][i]!=''
                pld_mcz_cbm = params[:dt_pld_mcz_cbm][i]
              else
                pld_mcz_cbm = ''
              end
                if pld_qty.to_i >0
                   create_packlist_linking(comp_codes,comp_type,pld_itemcode,pld_itemname,pld_number,pld_sale_type,pld_oa_number,pld_material,pld_color,pld_qty,pld_outer_qty,pld_box_no,pld_weight,pld_net_weight,pld_pck_weight,pld_gross_weight,pld_netvalues,bill_id,pld_position,pld_palletboxes,pld_boxtype,pld_icz_descp,pld_icz_size1,pld_icz_size2,pld_icz_size3,pld_icz_piece,pld_icz_cbm,pld_mcz_descp,pld_mcz_size1,pld_mcz_size2,pld_mcz_size3,pld_mcz_piece,pld_mcz_cbm)
                end
            i += 1
        end
     end
  end

end ## END CLASS
