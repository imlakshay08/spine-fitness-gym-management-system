## AUTHOR      :: UMESH CHAUHAN || ROR CONSULTANT & DEPLOYMENT OF LINUX(HOSTGATOR)
## HISTORY     :: 1.0.0
## DESCRIPTION :: This module control all common process integration for main controller
module ErpModule
  module Common 
   private
   def get_ledger_attached_file(compcodes,custid)
      custobj  = MstLedgerAttachment.where("sma_compcode=? AND sma_siteno=?",compcodes,custid)
     return custobj
   end
   private
   def formatted_times(times)
        newtime = ''
        if times!=nil && times !=''
             #dts    = Time.parse(times.to_s)
             newtime = times #dts.strftime("%H:%M")
        end
        return newtime
   end
    private
    def get_sewa_all_department
        compcode =  session[:loggedUserCompCode]
        disobj   =  Department.where("compCode = ? AND subdepartment=''",compcode).order("departDescription")
        return disobj
    end

    private
    def get_sewa_all_qualification
        compcode =  session[:loggedUserCompCode]
        disobj   =  MstQualification.where("ql_compcode = ?",compcode).order("ql_qualdescription ASC")
        return disobj
    end

    private
    def get_sewa_all_rolesresp
        compcode =  session[:loggedUserCompCode]
        disobj   =  MstResponsibility.where("rsp_compcode = ?",compcode).order("rsp_description ASC")
        return disobj
    end

    private
    def get_sewa_all_designation
        compcode =  session[:loggedUserCompCode]
        disobj   =  Designation.where("compcode = ?",compcode).order("ds_description ASC")
        return disobj
    end
    ########### CALL STORE PROCEDURES ############
    private
    def request_processor(sqls)
      results  = []           
       records_array = ActiveRecord::Base.connection.execute(sqls)
       ActiveRecord::Base.clear_active_connections!      
       records_array.each(as: :hash, symbolize_keys: true) do |row|
            results << OpenStruct.new(row)
          end
       return results
    end

   ########### END CALL STORE PROCEDURES ################
    ########## HR MONTHLY SALAY CALCULATION #########
      

      private
      def get_sewadar_monthly_list(compcode,sewacode,year="",months="")
        mobjs = []
        if year.to_i >0
            if months.to_i >=4 
              genfinalyear = year.to_s+"-"+(year.to_i+1).to_s
            else
              genfinalyear = (year.to_i-1).to_s+"-"+year.to_s
            end  
            isselect ="pm_paidleave,pm_workingday,pm_wo,pm_hl,pm_payyear,pm_monthday,pm_areaprvmonths,pm_areaprvyears,pm_paydays,pm_absent,pm_isposted,pm_unpaidleave"
            mobjs   = TrnPayMonthly.select(isselect).where("pm_compcode =? AND pm_sewacode =? AND pm_paymonth =? AND pm_payyear =?",compcode,sewacode,months,year).first
       end
        return mobjs
      end
      private
      def get_office_list_detail(compcode,empcode)
             sewdarobj =  MstSewadarOfficeInfo.where("so_compcode =? AND so_sewcode =?",compcode,empcode).first
             return sewdarobj
      end

      private
      def get_hr_parameters_head(compcode)
        hrsobj = MstHrParameterHead.where("hph_compcode = ?",compcode).first
        return hrsobj
      end

      private
      def get_electric_consumption(compcode,sewcode,years,month)
           electobj    = TrnElectricConsumption.where("ec_compcode =? AND ec_sewdarcode = ? AND ec_readingyear = ? AND LOWER(ec_readingmonth) =?",compcode,sewcode,years,month.to_s.downcase).first
           return electobj
      end

      private
      def get_hr_unit_rate(compcode,units)
        # hrsobj  =  MstHrParameterRange.where("hpr_compcode =? AND hpr_rangefrom <='#{units}' AND hpr_rangeto >='#{units}'",compcode).first
		 hrsobj   =  MstHrParameterRange.where("hpr_compcode =? AND hpr_rangefrom <='#{units}'",compcode).order("hpr_rangefrom ASC")
         return hrsobj
      end
      def get_accomodation_parmvalues(compcodes,acomotype)
          accmovalobj =  MstHrParameterAccomodation.where("hpa_compcode = ? AND hpa_types =?",compcodes,acomotype).first
          return accmovalobj
      end
      def get_allotment_detail(compcodes,sewcode)
         alotobj =  MstAccomodationAllotment.where("aa_compcode =? AND aa_sewadarcode =? AND aa_status ='Y'",compcodes,sewcode).first
        return alotobj
      end

    ##### END HR MONTHLY SLARY CACLCULATION #######
    
    private
   def get_name_of_product(compcodes,pdcode)

      if compcodes == 'all'
        iswhere = " pd_productcode='#{pdcode}'"
      else
        iswhere = " pd_compcode = '#{compcodes}' AND pd_productcode='#{pdcode}'"
      end
       prodobj =  MstProduct.select('pd_mrps,pd_brand,pd_barcode,pd_productcode,pd_productname,pd_weight,pd_gross_weight,pd_taxtincyesno,pd_refer_no,pd_category,pd_uom').where(iswhere).first
       return prodobj
    end

    def get_all_of_product(compcodes,pdcode)
      iswhere = " pd_compcode = '#{compcodes}' AND pd_productcode='#{pdcode}'"
       prodobj =  MstProduct.select("mst_products.*,'' as stckqty").where(iswhere).first
       return prodobj
    end
   private
   def get_sel_category(compcode,id)
     if id.to_i >0
       custobj = MstProductCategory.where("pc_compcode=? AND id=?",compcode,id).first
     else
       custobj = MstProductCategory.where("pc_compcode=?",compcode).first
     end
     
     return custobj
    end

   
    
   private
   def get_customer_detail(custid)
     compcodes     =  session[:loggedUserCompCode]
     custobj  = MstCustomer.select("cs_customername").where("cs_compcode=? AND id=?",compcodes,custid).first
     return custobj
   end

   private
   def get_company_detail(compcode)
     custobj = MstCompany.select("cmp_companycode,cmp_companyname").where("cmp_companycode=?",compcode).first
     return custobj
    end
    
   private
   def get_catalogue_detail(compcode,itemcode)
     catlogno = nil     
      if compcode == 'all'
        iswhere = " pd_productcode='#{itemcode}'"        
      else
        iswhere = " pd_compcode = '#{compcode}' AND pd_productcode='#{itemcode}'"
      end
     jprodobj = MstProduct.select('id').where(iswhere).first
     if jprodobj
        pdid = jprodobj.id
          if pdid.to_i >0
              if compcode == 'all'
                iscatlg = Productcatalog.select('id,pct_origin_img,pct_position').where("pct_isprimary='Y' AND pct_product_id=?",compcode,pdid).first
              else
                iscatlg = Productcatalog.select('id,pct_origin_img,pct_position').where("pct_compcode=? AND pct_isprimary='Y' AND pct_product_id=?",compcode,pdid).first
              end
              
              if iscatlg
                  catlogno = iscatlg
              end

          end
     end
     return catlogno
   end
   private
   def get_stocks_detail(compcode,pdcode)    
      if compcode == 'all'
        iswhere = " cb_pdcode='#{pdcode}'"
      else
        iswhere = " cb_pdcode='#{pdcode}' AND cb_compcode='#{compcode}'"
      end
      custobj = MstClosingBalance.select("SUM(cb_closing_bal) as tstock,cb_closing_bal,cb_opening_bal").where(iswhere).first
      return custobj
    end
   private
   def get_high_priority_qtydetail(compcode,billnumber,saletype,hd_priority)    
     if compcode == 'all'
        iswhere = " dt_billnumber='#{billnumber}' AND dt_sale_type='#{saletype}'"
      else
        iswhere = " dt_compcode='#{compcode}' AND dt_billnumber='#{billnumber}' AND dt_sale_type='#{saletype}'"
      end
     isgroupby = "TRIM(dt_itemcode),TRIM(dt_material),TRIM(dt_color)"
     custobj = nil
     if hd_priority =='high'
     custobj = TrnProformaDetail.select('SUM(dt_quantity) as hightqty').where(iswhere).group(isgroupby)
     
    end
    return custobj
   end

   private
   def format_oblig_date(dates)
        newdate = ''
        begin
        if dates!=nil && dates!=''
             dts    = Date.parse(dates.to_s)
             newdate = dts.strftime("%d/%m/%Y")
        end
        rescue Exception=>error
          ## execute message
        end
        return newdate
   end
   ### Days-Month-YEAR WISE
   private
   def formatted_date(dates)
        newdate = ''
        begin
        if dates!=nil && dates!=''
             dts    = Date.parse(dates.to_s)
             newdate = dts.strftime("%d-%b-%Y")
        end
      rescue Exception=>error
        ## execute message
      end
        return newdate
   end
   ### Year-Month-Date WISE
   private
   def year_month_days_formatted(dates)
        newdate = ''
        begin 
        if dates!=nil && dates!=''
             dts    = Date.parse(dates.to_s)
             newdate = dts.strftime("%Y-%m-%d")
        end
      rescue Exception=>error
        ## execute message
      end
        return newdate
   end
   
   private
   def financial_session_date
      nyears   = Time.now-1.years
      month    = Time.now.to_date.strftime("%m")
      if( month.to_i >= 1 && month.to_i <= 3 )
        years  = nyears.to_date.strftime("%Y")
      else
        years  = Time.now.to_date.strftime("%Y")
      end      
      ndate  = years.to_s+"-04-01"
      return ndate
   end
   
   private
   def last_financial_session_date
      nyears   = Time.now+1.years
      month    = Time.now.to_date.strftime("%m")
      if( month.to_i >= 1 && month.to_i <= 3 )
        years    = Time.now.to_date.strftime("%Y")
      else
        years    = nyears.to_date.strftime("%Y")
      end
      
      ndate    = years.to_s+"-03-31"
      return ndate
   end

   private
   def financial_session_years
      nyears   = Time.now-1.years
      month    = Time.now.to_date.strftime("%m")
      if( month.to_i >= 1 && month.to_i <= 3 )
        years  = nyears.to_date.strftime("%Y")
      else
        years  = Time.now.to_date.strftime("%Y")
      end
      ndate  = years.to_s
      return ndate
   end

   private
   def last_financial_session_years
      nyears   = Time.now+1.years
      month    = Time.now.to_date.strftime("%m")
      if( month.to_i >= 1 && month.to_i <= 3 )
        years    = Time.now.to_date.strftime("%Y")
      else
        years    = nyears.to_date.strftime("%Y")
      end

      ndate    = years.to_s
      return ndate
   end


   
   private
   def currency_formatted(amt)
        amts = ''
        if amt!=nil && amt!=''
          amts = "%.2f" % amt.to_f
        end
        return amts
   end
   private
   def set_ent(items)
     Base64.encode64(items)
   end
    private
   def set_dct(items)
     Base64.decode64(items)
   end
  end ### sub module

end ## main module
