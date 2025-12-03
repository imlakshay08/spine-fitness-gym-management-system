class CompanyController < ApplicationController
    before_action :require_login  
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    def index
        @compcodes      =  session[:loggedUserCompCode]
        @logedId        =  session[:autherizedUserId]
        cid             = '99'
        @companyState   = MstInqState.where(["cid = ?", cid])
        @companyCountry = MstInqCountry.where(["1"])
        @companyItems   = MstCompany.where(["cmp_companycode = ?", @compcodes]).first    
        
    end
    def create
     @compcodes =  session[:loggedUserCompCode]
     @logedId   =  session[:autherizedUserId]
     isFlags    = true
     
     begin
      
      if session[:autherizedUserType].to_s!=nil && session[:autherizedUserType].to_s=='inq'
        @compcodes = ''
      end
     if params[:cmp_companyname]=='' || params[:cmp_companyname]==nil
         flash[:error] =  "Please enter company name!"
         isFlags = false
      elsif params[:cmp_companycode]==''|| params[:cmp_companycode]==nil
         flash[:error] =  "Invalid company!"
         isFlags = false
     elsif params[:cmp_email]==''|| params[:cmp_email]==nil
          flash[:error] =  "Please enter email Id!"
          isFlags = false 
      else
     
          ismobiles =  params[:cmp_cell_number].to_s.strip  
          if ismobiles.length <10
            flash[:error] = "Mobile number should be at least 10 digits!"
            isFlags = false
          end 
           
           
           if isFlags          
            
            if session[:autherizedUserType].to_s!=nil && session[:autherizedUserType].to_s=='inq'
                        isCompCode = params[:cmp_companycode].to_s.strip                    
                        if isCompCode.length <5
                                flash[:error] = "Minimum company code will be 5 digits!!"
                                isFlags = false
                        else
                                @company  = MstCompany.where("cmp_companycode=? ",params[:cmp_companycode].to_s.strip)
                                if @company.count >0
                                     flash[:error] = "This company code is already taken!, Please try another code!!"
                                     isFlags = false
                                else
                                      isemails  =  params[:cmp_email].to_s.strip
                                                                 
                                   
                                      if isFlags
                                            @comp = MstCompany.new(company_params)
                                            if @comp.save
                                            set_company_users(params[:cmp_companycode],isemails,ismobiles)
                                            #save_business_items()
                                            flash[:error] =  "Data saved successfully!!"
                                            isFlags = true
                                            end
                                      end
                                end
                          end
                   else
                       ####### Check Duplicate GST NUMBER##################                   
                            # if params[:cmp_gstname].to_s!='' && params[:cmp_gstname].to_s!=nil
                            #     if params[:currentgstnumber].to_s.strip!=params[:cmp_gstname].to_s.strip
                            #         @DPGSTCoMP  = MstCompany.where("cmp_gstname=?",params[:cmp_gstname].to_s.strip)
                            #          if @DPGSTCoMP.length >0
                            #             flash[:error] = "Duplicate GST number is not allowed!!"                                   
                            #             isFlags  = false
                            #          end
                            #     end
                            # end
                        ####### END ####################
                        if params[:cmp_companycode]!= nil && params[:cmp_companycode]!=''
                              if isFlags
                                  @company = MstCompany.where("cmp_companycode=? ",params[:cmp_companycode]).update(company_params)
                                  #save_business_items()
                                  
                                  flash[:error] =  "Data updated successfully!!"
                                  isFlags = true
                              end
    
                          else
                              if isFlags
                                  @comp = MstCompany.new(company_params)
                                  if @comp.save
                                    #save_business_items()
                                   
                                    flash[:error] =  "Data saved successfully!!"
                                    isFlags = true
                                 end
                              end
                         end
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
           flash[:error] =  "ERROR: #{exc.message}"
           session[:isErrorhandled] = 1
          #session[:postedpamams]   = params
           isFlags = false
       end
      if !isFlags
        redirect_to :action=>:index
      else
        redirect_to "#{root_url}"+"dashboard"
      end
    
    end
    
    def show
         if params[:comp_gstin_variable]!='' && params[:comp_gstin_variable]!=nil && params[:comp_gstin_variable]=='Y'
            get_state_code_from_gstin()
         elsif params[:sendsms_bankdetail]!='' && params[:sendsms_bankdetail]!=nil && params[:sendsms_bankdetail]=='Y'
            send_sms_for_bank_detail()
         elsif params[:iscompany_termscondition]!='' && params[:iscompany_termscondition]!=nil && params[:iscompany_termscondition]=='Y'
            get_company_tc_details()
         end
    end
  

    def destroy
    @company = MstCompany.find(params[:id])
    @company.destroy
    redirect_to :action=>:index
    end
    ####### COMPANY SETTING FROM HERE########################
    
    def company_setting
     @compcodes =  session[:loggedUserCompCode]
     @logedId   =  session[:autherizedUserId]
     isFlags    = true
     @isMessage = ''
     @iSuccessMessage = ''
     begin
     if @compcodes == '' || @compcodes==nil
         flash[:error] =  "Invalid company code!"
         isFlags       = false
     end
     if params[:redirectParam]!='' && params[:redirectParam]!=nil && params[:redirectParam]=='STT'
            if isFlags
                if params[:iscompanyEdId].to_i >0
                    @isCompsett = MstCompanySetting.where("cps_compcode=? ",@compcodes).first
                    @isCompsett.update(param_comp_setts)
                    isFlags       = true
                    flash[:error] =  "Data updated successfully!"
                    company_sale_setting
                else
                   @Necomp =  MstCompanySetting.new(param_comp_setts)
                   if @Necomp.save
                    isFlags       = true
                    flash[:error] =  "Data saved successfully!"
                    company_sale_setting
                   end
                end
           end
     elsif params[:redirectParam]!='' && params[:redirectParam]!=nil && params[:redirectParam]=='SMS'    
        message_params()
        flash[:error] = @iSuccessMessage
        isFlags = true
     elsif params[:redirectParam]!='' && params[:redirectParam]!=nil && params[:redirectParam]=='EML'
        email_save_params()
        flash[:error] = @iSuccessMessage
        isFlags  = true
     elsif params[:redirectParam]!='' && params[:redirectParam]!=nil && params[:redirectParam]=='COMPSET'
        set_debitor_creditor()
        flash[:error] = @iSuccessMessage
        isFlags  = true
     end
     @compsObj     = MstCompany.where(["cmp_companycode = ?", @compcodes]).first
     @isTemplate   = MstSmsEmailTemplate.where("smt_compcode=? ",@compcodes)
     @isAllcomp    = MstCompanySetting.where("cps_compcode=? ",@compcodes).first
     @myCompSale1  = MstSaleType.where("st_compcode=? and st_status='Y'",@compcodes)
     @allModules   = MstModule.select('mds_num_loc,mds_location').where("mds_compcode = ?",@compcodes).first
     @myCompSale   = []
     if @myCompSale1
        @myCompSale1.each do |km|
        @myCompSale.push(km.st_sale_type)
       end
      end
     @isSB = false
     @isSP = false
     @isSR = false
     @isSS = false
     @isEB = false
     @isEP = false
     @isER = false
     @isES = false
     @isSA = false
     @isEA = false
     @vSB  = ""
     @vSP  = ""
     @vSR  = ""
     @vSS  = ""
     @vEB  = ""
     @vEP  = ""
     @vER  = ""
     @vES  = ""
     @vESB = ""
     @vESP = ""
     @vESR = ""
     @vESS = ""
      if @isTemplate
       @isTemplate.each do |esms|
         if esms.smt_bill_type.to_s!=nil && esms.smt_bill_type.to_s!='' && esms.smt_bill_type.to_s=='sms'
                      if esms.smt_type.to_s!=nil && esms.smt_type.to_s!='' && esms.smt_type.to_s =='Bill'
                        @isSB = (esms.smt_active.to_s=='Y') ? true : false
                        @vSB  = esms.smt_message.to_s
                      end
                      if esms.smt_type.to_s!=nil && esms.smt_type.to_s!='' && esms.smt_type.to_s =='Payment'
                        @isSP = (esms.smt_active.to_s=='Y') ? true : false
                        @vSP  = esms.smt_message.to_s
                      end
                      if esms.smt_type.to_s!=nil && esms.smt_type.to_s!='' && esms.smt_type.to_s =='Receive'
                        @isSR = (esms.smt_active.to_s=='Y') ? true : false
                        @vSR  = esms.smt_message.to_s
                      end
                      if esms.smt_type.to_s!=nil && esms.smt_type.to_s!='' && esms.smt_type.to_s =='Statement'
                        @isSS = (esms.smt_active.to_s=='Y') ? true : false
                        @vSS  = esms.smt_message.to_s
                      end
                      if esms.smt_autosend.to_s!=nil && esms.smt_autosend.to_s!='' && esms.smt_autosend.to_s =='Y'
                         @isSA = true
                      end
           
         end #end if
         if esms.smt_bill_type.to_s!=nil && esms.smt_bill_type.to_s!='' && esms.smt_bill_type.to_s=='email'
                      if esms.smt_type.to_s!=nil && esms.smt_type.to_s!='' && esms.smt_type.to_s =='Bill'
                        @isEB = (esms.smt_active.to_s=='Y')  ? true :false
                        @vEB  = esms.smt_message.to_s
                        @vESB = esms.smt_subject.to_s
                      end
                      if esms.smt_type.to_s!=nil && esms.smt_type.to_s!='' && esms.smt_type.to_s =='Payment'
                        @isEP = (esms.smt_active.to_s=='Y')  ? true :false
                        @vEP  = esms.smt_message.to_s
                        @vESP = esms.smt_subject.to_s
                      end
                      if esms.smt_type.to_s!=nil && esms.smt_type.to_s!='' && esms.smt_type.to_s =='Receive'
                        @isER = (esms.smt_active.to_s=='Y')  ? true :false
                        @vER  = esms.smt_message.to_s
                        @vESR = esms.smt_subject.to_s
                      end
                      if esms.smt_type.to_s!=nil && esms.smt_type.to_s!='' && esms.smt_type.to_s =='Statement'
                        @isES = (esms.smt_active.to_s=='Y') ? true :false
                        @vES  = esms.smt_message.to_s
                        @vESS = esms.smt_subject.to_s
                      end
                      if esms.smt_autosend.to_s!=nil && esms.smt_autosend.to_s!='' && esms.smt_autosend.to_s =='Y'
                         @isEA = true
                      end
         end #end if
       end## end foreach
     end ## end if
    
     @isPreAllowed  = 0
     @isProfAllowed = 0
     @isCheckAllw   = TrnHdr.where("hd_compcode = ? ",@compcodes).first
     @isCheckProf   = TrnProformaHdr.where("hd_compcode = ? ",@compcodes).first
     if @isCheckAllw
        if @isCheckAllw.hd_compcode.to_s!=nil && @isCheckAllw.hd_compcode.to_s!='' && @isCheckAllw.hd_compcode.to_s==@compcodes.to_s
          @isPreAllowed = 1
        end
     end
    if @isCheckProf
        if @isCheckProf.hd_compcode.to_s!=nil && @isCheckProf.hd_compcode.to_s!='' && @isCheckProf.hd_compcode.to_s==@compcodes.to_s
          @isProfAllowed = 1
        end
     end
      if !isFlags
        session[:isErrorhandled] = 1
       # session[:postedpamams]   = params
    
      else
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        isFlags = true
      end
       rescue Exception => exc
           flash[:error] =  "ERROR: #{exc.message}"
           session[:isErrorhandled] = 1
          # session[:postedpamams]   = params
           isFlags = false
       end
     
      if params[:redirectParam]!='' && params[:redirectParam]!=nil
        redirect_to "#{root_url}"+"company/company_setting"
      end
    end
    
    private
    def company_sale_setting
    
        k = 0
         if params[:picksale]!=nil && params[:picksale]!=''
          params[:picksale].each do |itm|
    
             if params['picksale'][k].to_s!='' && params['picksale'][k].to_s!=nil
                     @isCompSale = MstSaleType.where("st_compcode=? AND st_sale_type=? ",@compcodes,params['picksale'][k])
                     if @isCompSale.count >0
                      if params['picksale'][k] == 'S'
                         @isCompSale.update(:st_compcode=>@compcodes,:st_sale_type=>params['picksale'][k],:st_status=>'Y')
                         save_after_use_sale_type(params['picksale'][k])
                       elsif params['picksale'][k] == 'SL' || params['picksale'][k] == 'SO'
                         @isCompSale.update(:st_compcode=>@compcodes,:st_sale_type=>params['picksale'][k],:st_status=>'Y')
                         save_after_use_sale_type(params['picksale'][k])
                      end
    
                      else
                        @newObj = MstSaleType.new(:st_compcode=>@compcodes,:st_sale_type=>params['picksale'][k],:st_status=>'Y')
                        if @newObj.save
                        ###
                        end
                     end
               end
               k +=1
             end
         end
    end
    
    def save_after_use_sale_type(slObj)
    if slObj == 'S'
       @isCompSales = MstSaleType.where("st_compcode=? AND st_sale_type<>? ",@compcodes,slObj)
       @isCompSales.update(:st_compcode=>@compcodes,:st_status=>'N')
     elsif slObj == 'SL' || slObj == 'SO'
       @isCompSales = MstSaleType.where("st_compcode=? AND st_sale_type=? ",@compcodes,'S')
       @isCompSales.update(:st_compcode=>@compcodes,:st_status=>'N')
     end
    end
    
    
    def create_configuration_sale_type(slObj,compCode)
      @compcodes  = compCode
      @isCompSale = MstSaleType.where("st_compcode=? AND st_sale_type<>? ",compCode,slObj)
      if @isCompSale.count >0
         @isCompSale.update(params_sale_type)
       else
          @nwCompSale = MstSaleType.new(params_sale_type)
          if @nwCompSale.save
            #execute message
          end
       end
    end
    
    
    
    def params_sale_type
     params[:st_compcode]  = @compcodes
     params[:st_sale_type] = 'S'
     params[:st_status]    = 'Y'
     params.permit(:st_compcode,:st_sale_type,:st_status)
    end
    
    
    
    private
    def param_comp_setts
      params[:cps_compcode] = @compcodes
      if  params[:cps_isbarcode] == '' || params[:cps_isbarcode]==nil
         params[:cps_isbarcode] = 'N'
    
      end
      if  params[:cps_isvehicle] == '' || params[:cps_isvehicle]==nil
         params[:cps_isvehicle] = 'N'
    
      end
      if  params[:cps_issalesman] == '' || params[:cps_issalesman]==nil
         params[:cps_issalesman] = 'N'
    
      end
      if  params[:cps_isdispmode] == '' || params[:cps_isdispmode]==nil
         params[:cps_isdispmode] = 'N'
    
      end
      if  params[:cps_isvalidno] == '' || params[:cps_isvalidno]==nil
         params[:cps_isvalidno] = 'N'
    
      end
      if  params[:cps_isgroup] == '' || params[:cps_isgroup]==nil
         params[:cps_isgroup] = 'N'
    
      end
    
      if  params[:cps_isemc] == '' || params[:cps_isemc]==nil
         params[:cps_isemc] = 'N'
    
      end
      if  params[:cps_delete] == '' || params[:cps_delete]==nil
         params[:cps_delete] = 'N'
    
      end
      if  params[:cps_cancel] == '' || params[:cps_cancel]==nil
         params[:cps_cancel] = 'N'
      end
      if  params[:cps_isdriverdt] == '' || params[:cps_isdriverdt]==nil
         params[:cps_isdriverdt] = 'N'
      end
      if  params[:cps_clb] == '' || params[:cps_clb]==nil
         params[:cps_clb] = 'N'
      end
    
      if  params[:cps_updates] == '' || params[:cps_updates]==nil
         params[:cps_updates] = 'N'
      end
      if  params[:cps_proforma] == '' || params[:cps_proforma]==nil
         params[:cps_proforma] = 'N'
      end
      if  params[:cps_updated_status] == '' || params[:cps_updated_status]==nil
         params[:cps_updated_status] = 'Y'
      end
      if  params[:cps_show_address] == '' || params[:cps_show_address]==nil
          params[:cps_show_address] = 'Y'
      end
      if  params[:cps_prd_bar_show] == '' || params[:cps_prd_bar_show]==nil
          params[:cps_prd_bar_show] = 'N'
      end
      if  params[:cps_prd_ctn_show] == '' || params[:cps_prd_ctn_show]==nil
          params[:cps_prd_ctn_show] = 'N'
      end
       params[:cps_print_slip]         = params[:cps_print_slip]!= '' && params[:cps_print_slip]!= nil ? params[:cps_print_slip] : 'N'
       params[:cps_scan_serial_no]     = params[:cps_scan_serial_no]!= '' ? params[:cps_scan_serial_no] : 'N'
       params[:cps_stock_challan]      = params[:cps_stock_challan]!='' ? params[:cps_stock_challan] : 'N'
       params[:cps_dropdown_multi]     = params[:cps_dropdown_multi]!='' ? params[:cps_dropdown_multi] : 'N'
       params[:cps_round_amt]          = params[:cps_round_amt]!='' ? params[:cps_round_amt] : 'N'
       params[:cps_search_item_counts] = params[:cps_search_item_counts].delete(' ')!='' ? params[:cps_search_item_counts] : 0
       params[:cmp_extraweekfirst]     = params[:cmp_extraweekfirst]!= '' && params[:cmp_extraweekfirst]!= nil ? params[:cmp_extraweekfirst] : 0
       params[:cmp_extraweeksec]       = params[:cmp_extraweeksec]!= '' && params[:cmp_extraweeksec]!= nil ? params[:cmp_extraweeksec] : 0
       params[:cmp_extradaysfirst]     = params[:cmp_extradaysfirst]!= '' && params[:cmp_extradaysfirst]!= nil ? params[:cmp_extradaysfirst] : 0
       params[:cmp_extradayssec]       = params[:cmp_extradayssec]!= '' && params[:cmp_extradayssec]!= nil ? params[:cmp_extradayssec] : 0
       params[:cmp_latecounts]         = params[:cmp_latecounts]!= '' && params[:cmp_latecounts]!= nil ? params[:cmp_latecounts] : 0
       params[:cmp_latededctdays]      = params[:cmp_latededctdays]!= '' && params[:cmp_latededctdays]!= nil ? params[:cmp_latededctdays] : 0
       
       params.permit(:cps_compcode,:cmp_latecounts,:cmp_latededctdays,:cmp_extradaysfirst,:cmp_extradayssec,:cmp_extraweekfirst,:cmp_extraweeksec,:cps_print_slip,:cps_clb,:cps_updates,:cps_delete,:cps_cancel,:cps_isbarcode,:cps_isvehicle,:cps_issalesman,:cps_isdispmode,:cps_isvalidno,:cps_isgroup,:cps_isemc,:cps_isdriverdt,:cps_proforma,:cps_updated_status,:cps_show_address,:cps_dropdown_multi,:cps_prd_bar_show,:cps_prd_ctn_show,:cps_search_item_counts,:cps_round_amt,:cps_stock_challan,:cps_scan_serial_no)
    
    end
    ############## END COMAPNY SETTING###########
    
    
    
    
    private
    def set_company_users(compcode,emails,ismobiles)
        isUserFlg = false
        if compcode!= nil && compcode!=''
            passds      = _random_string_(8)       
            user        = compcode.to_s.delete(' ') ##+addusrs.to_s
            permsiions  = "COP,USR,CST,GRP,SLS,LOC,PRD,BRD,CAT,UOM,INV,PI,RCV,PMT,PGP,P,PR,SR,RS,RP,RPR,RSR,RLG,RLGS,RENP,RCHQ,PDR,PDRS,RPMTS,RRCVD"
            passd       = passds.to_s.delete(' ')
            @isPassword = passd
            @isUserId   = user
            xpassword   = Digest::MD5.hexdigest(passd)
            @LogUser    = User.where("username=? ",user)
            @receiver   = params[:cmp_companyname].to_s
            emailId     = params[:cmp_email].to_s
            mobileNumb  = params[:cmp_cell_number].to_s
            bodys       = mailFormats
            if @LogUser.count >0
                    @LogUser.update(:usercompcode=>compcode,:username=>user,:userpassword=>xpassword,:userpermission=>permsiions,:phonenumber=>mobileNumb,:email=>emailId,:spspermission=>'',:product_prefix=>'',:product_length=>0,:usertype=>'adm')
                    isUserFlg = true
                    UserMailMailer.generatelogin_confrimation(passd,user,emails,bodys).deliver
                    if ismobiles!=nil
                     UserMailMailer.send_sms_to_users(ismobiles,user,passd).deliver
                    end
            else
                    @User = User.new(:usercompcode=>compcode,:username=>user,:userpassword=>xpassword,:userpermission=>permsiions,:phonenumber=>mobileNumb,:email=>emailId,:spspermission=>'',:product_prefix=>'',:product_length=>0,:usertype=>'adm')
                    if @User.save
                       isUserFlg = true
                       create_configuration_sale_type('S',compcode)
                       set_auto_generated_trial_customers(compcode)
                       UserMailMailer.generatelogin_confrimation(passd,user,emails,bodys).deliver
                       if ismobiles!=nil
                       UserMailMailer.send_sms_to_users(ismobiles,user,passd).deliver
                       end
                    end
            end
        end
    end
    
    ######################## AUTO GENERATED 15 DAYS TRIAL ##############
    private
    def set_auto_generated_trial_customers(compcode)
      @trialdate = Date.today() + 15
      @isExpVald = MstCompanyValidity.where("cv_compcode=? ",compcode)
      if @isExpVald.count >0
         #@isExpVald.update(params_sale_type)
       else
          @isExpSave = MstCompanyValidity.new(:cv_compcode=>compcode,:cv_total_days=>0,:cv_expiry_date=>@trialdate,:cv_upgrade_status=>'Y',:cv_status=>'free')
          if @isExpSave.save
            #execute message
          end
       end
    end
    
    private
    def company_params
    @new_file_name_with_type  = nil
    @new_file_name_with_types = nil
    
      if params[:cmp_companyname]!='' || params[:cmp_companyname]!=nil
          params[:cmp_companyname] = params[:cmp_companyname].upcase
      end
      params[:cmp_telephonenumber] = params[:cmp_telephonenumber]!='' && params[:cmp_telephonenumber]!=nil ? params[:cmp_telephonenumber] : ''
      params[:cmp_addressline3]    = params[:cmp_addressline3]!='' && params[:cmp_addressline3]!=nil ? params[:cmp_addressline3] : ''
      params[:cmp_gstname]         = params[:cmp_gstname]!='' &&  params[:cmp_gstname]!=nil ? params[:cmp_gstname] : '0'
      params[:cmp_pannumber]       = params[:cmp_pannumber]!='' && params[:cmp_pannumber]!=nil ? params[:cmp_pannumber] : ''
      params[:cmp_adharnumber]     = params[:cmp_adharnumber]!='' &&  params[:cmp_adharnumber]!=nil ? params[:cmp_adharnumber] : ''
      params[:cmd_pfcalculated]    = params[:cmd_pfcalculated]!=nil && params[:cmd_pfcalculated]!='' ? params[:cmd_pfcalculated] : ''
     
      if params[:cmp_logos]=='' || params[:cmp_logos]==nil
        params[:cmp_logos] = ''
      end
      if params[:cmp_signs]=='' || params[:cmp_signs]==nil
         params[:cmp_signs] = ''
      end
     
      if params[:cmp_logos]!= '' && params[:cmp_logos]!=nil
        @new_file_name_with_type = upload_logo_server_image()
        params[:cmp_logos] = @new_file_name_with_type
      end
      if @new_file_name_with_type == nil
          if params[:currentcomplogo]!= ''
            params[:cmp_logos] = params[:currentcomplogo]
          end
      end
      
      if params[:cmp_signs]!= '' && params[:cmp_signs]!=nil
        @new_file_name_with_types = upload_signs_server_image()
        params[:cmp_signs] = @new_file_name_with_types
      end
      if @new_file_name_with_types == nil
          if params[:currentcompsigns]!= '' && params[:currentcompsigns]!= nil
            params[:cmp_signs] = params[:currentcompsigns]
          end
      end
      if params[:cmp_show_logo]== nil || params[:cmp_show_logo]== ''
        params[:cmp_show_logo] = 'N'
      end
      
      
      ######### ADD GST NUMBER ###############
      if params[:cmp_gstname]!=nil && params[:cmp_gstname]!=''
          if params[:cmp_gstname].to_s.length >0
             session[:authorizedGSTNumber] = params[:cmp_gstname]
          else
            session[:authorizedGSTNumber]  = nil
          end
      else
            session[:authorizedGSTNumber] = nil
      end
      if params[:cmp_cell_number]!=nil && params[:cmp_cell_number]!=''
         params[:cmp_cell_number] = params[:cmp_cell_number].to_s.delete(' ')
      end
      if params[:cmp_email]!=nil && params[:cmp_email]!=''
         params[:cmp_email] = params[:cmp_email].to_s.strip.downcase
      end
      ######### END GST NUMBER#####################
      
       params[:cmp_status]             = 'Y'  
    #    params[:cmp_unitname]           = ( params[:cmp_unitname]!= '' ) ? params[:cmp_unitname].strip : ''
    #    params[:cmp_gst_registered]     = ( params[:cmp_gst_registered].to_s.length.to_i >0 ) ? params[:cmp_gst_registered] : 'N' 
    #    params[:cmp_tradename]          = ( params[:cmp_tradename].to_s.length.to_i >0 ) ? params[:cmp_tradename] : ''  
    #    params[:cmp_gstname]            = ( params[:cmp_gstname].to_s.length.to_i >0 ) ? params[:cmp_gstname] : ''  
    #    params[:cmp_advance_sss]        = params[:cmp_advance_sss]!=nil && params[:cmp_advance_sss]!='' ? params[:cmp_advance_sss] : ''
    #    params[:cmp_latecoming]         = params[:cmp_latecoming]!=nil && params[:cmp_latecoming]!='' ? params[:cmp_latecoming] : ''
    #    params[:cmp_extraweekfirst]     = params[:cmp_extraweekfirst]!= '' && params[:cmp_extraweekfirst]!= nil ? params[:cmp_extraweekfirst] : 0
    #    params[:cmp_extraweeksec]       = params[:cmp_extraweeksec]!= '' && params[:cmp_extraweeksec]!= nil ? params[:cmp_extraweeksec] : 0
    #    params[:cmp_extradaysfirst]     = params[:cmp_extradaysfirst]!= '' && params[:cmp_extradaysfirst]!= nil ? params[:cmp_extradaysfirst] : 0
    #    params[:cmp_extradayssec]       = params[:cmp_extradayssec]!= '' && params[:cmp_extradayssec]!= nil ? params[:cmp_extradayssec] : 0
    #    params[:cmp_latecounts]         = params[:cmp_latecounts]!= '' && params[:cmp_latecounts]!= nil ? params[:cmp_latecounts] : 0
    #    params[:cmp_latededctdays]      = params[:cmp_latededctdays]!= '' && params[:cmp_latededctdays]!= nil ? params[:cmp_latededctdays] : 0
    #    params[:cmp_salary_calon]       = params[:cmp_salary_calon] !=nil && params[:cmp_salary_calon] !='' ? params[:cmp_salary_calon]  : ''
    #    params[:cmp_extrahlfday]        = params[:cmp_extrahlfday].to_s.present? ? params[:cmp_extrahlfday].to_f : 0
    #    params[:cmp_extrahlwork]        = params[:cmp_extrahlwork].to_s.present? ? params[:cmp_extrahlwork].to_f : 0
    #    params[:cmp_activestatus]       = params[:cmp_activestatus].to_s.present? ? params[:cmp_activestatus].to_s.strip : ''
       
       
       if session[:autherizedUserType].to_s!=nil && session[:autherizedUserType].to_s=='inq'
          iscompcode               = params[:cmp_companycode].to_s.delete(' ').upcase
          params[:cmp_companycode] = iscompcode;
          params.permit(:cmp_companycode,:cmp_activestatus,:cmp_extrahlfday,:cmp_extrahlwork,:cmp_salary_calon,:cmp_latecounts,:cmp_latededctdays,:cmp_extradaysfirst,:cmp_extradayssec,:cmp_extraweekfirst,:cmp_extraweeksec,:cmp_advance_sss,:cmp_latecoming,:cmd_pfcalculated,:cmp_companyname,:cmp_tradename,:cmp_gstname,:cmp_addressline1,:cmp_addressline2,:cmp_addressline3,:cmp_telephonenumber,:cmp_cell_number,:cmp_countrycode,:cmp_stateandcode,:cmp_email,:cmp_pannumber,:cmp_adharnumber,:cmp_max_workdays,:cmp_logos,:cmp_esicode_no,:cmp_pfcodeno,:cmp_signs,:cmp_show_logo,:cmp_status,:cmp_unitname,:cmp_nof_user,:cmp_validity)
       else
          params.permit(:cmp_companycode,:cmp_activestatus,:cmp_companyname,:cmp_addressline1,:cmp_addressline2,:cmp_addressline3,:cmp_telephonenumber,:cmp_cell_number,:cmp_countrycode,:cmp_stateandcode,:cmp_max_workdays,:cmp_email,:cmp_pannumber,:cmp_adharnumber,:cmp_logos,:cmp_signs,:cmp_show_logo,:cmp_status)
       end
    
    end
    
    
    private
    def message_params
      @compcodes  =  session[:loggedUserCompCode] 
      if params[:smsautosend]=='' || params[:smsautosend]==nil
          smt_autosend = 'N'
      else
         smt_autosend  = params[:smsautosend]
      end
      
      k = 0
     smt_compcode  = @compcodes
     smt_subject   = ''
     smt_message   = ''
     isactive      = ''
     smt_bill_type = "sms"
     p = 0
    #if params[:sendSmsdetail]!=nil
       # params[:sendSmsdetail].each do |sends|
       for k in 0..3
               if params["rcvbcommonSms"][k] != '' && params["rcvbcommonSms"][k] != nil
                 smt_message  =  params["rcvbcommonSms"][k]
                 p +=1
               else
                 smt_message  =  ''
              end         
              if k.to_i==0
              smt_type  = "Bill"
              isactive  = params[:isBilled][k]
              elsif k.to_i==1
              smt_type  = "Payment"
              isactive  = params[:isBilled][k]
              elsif k.to_i==2
              smt_type  = "Receive"
              isactive  = params[:isBilled][k]
              elsif k.to_i==3
              smt_type  = "Statement"
              isactive  = params[:isBilled][k]
              end
             save_email_sms_format(smt_compcode,smt_type,smt_subject,smt_message,smt_bill_type,smt_autosend,isactive)
             k +=1
        end
    #end
      if p.to_i <=0
        @iSuccessMessage = "Please select atleast one field for processsing!"
        session[:isErrorhandled] = 1
      else
        session[:isErrorhandled]  =nil
      end
      
    end
    
    
    
    private
    def corp_image_size
      @paXths = Rails.root.join "public", "images", "logo","thumb"
      file = "#{@paths}/"+@Imgs
      if File.exist?(file)
      image = MiniMagick::Image.new(file)
      image.resize "200x60"
      image.write("#{@paXths}/"+@Imgs)
      end
    end
    
    private
      def upload_logo_server_image
        file_name     =  params[:cmp_logos].original_filename  if  ( params[:cmp_logos] !='')
        file          =  params[:cmp_logos].read
        file_type     =  file_name.split('.').last
        new_name_file = Time.now.to_i    
        new_file_name_with_type = "#{new_name_file}." + file_type
        @Imgs = new_file_name_with_type
        @paths = Rails.root.join "public", "images", "logo"
        #### Delete Origins#############
        if params[:cmp_logos]!= '' && params[:cmp_logos]!= nil
           if params[:currentcomplogo]!= '' && params[:currentcomplogo]!= nil
             @curpath1 = Rails.root.join "public", "images", "logo",params[:currentcomplogo].to_s
             unlinks_the_files(@curpath1)
           end
        end
        #### Delete thumbs#############
        if params[:cmp_logos]!= '' && params[:cmp_logos]!= nil
           if params[:currentcomplogo]!= '' && params[:currentcomplogo]!= nil
             @curpath2 = Rails.root.join "public", "images", "logo","thumb",params[:currentcomplogo].to_s
             unlinks_the_files(@curpath2)
           end
        end
        ######### Upload here ######################
        File.open("#{@paths}/" + new_file_name_with_type, "wb")  do |f|
          f.write(file)
        end
       # corp_image_size
        return new_file_name_with_type
      end
    ######## SIGN ###########
    private
    def corp_image_size_signs
      @paXths = Rails.root.join "public", "images", "signs","thumb"
      file = "#{@paths}/"+@Imgs
      if File.exist?(file)
      image = MiniMagick::Image.new(file)
      image.resize "200x60"
      image.write("#{@paXths}/"+@Imgs)
      end
    end
    
    private
      def upload_signs_server_image
        file_names     =  params[:cmp_signs].original_filename  if  ( params[:cmp_signs] !='')
        files          =  params[:cmp_signs].read
        file_types     =  file_names.split('.').last
        new_name_files =  Time.now.to_i
        new_file_name_with_types = "#{new_name_files}." + file_types
        @Imgs1   = new_file_name_with_types
        @paths1  = Rails.root.join "public", "images", "signs"
        #### Delete Origins#############
        if params[:cmp_signs]!= '' && params[:cmp_signs]!= nil 
           if params[:currentcompsigns]!= '' && params[:currentcompsigns]!= nil
             @curpath = Rails.root.join "public", "images", "signs",params[:currentcompsigns].to_s
             unlinks_the_files(@curpath)
           end
        end
        ######### Upload here ######################
        File.open("#{@paths1}/" + new_file_name_with_types, "wb")  do |f|
          f.write(files)
        end
        #corp_image_size_signs
        return new_file_name_with_types
      end
    
      private
      def unlinks_the_files(path_to_file)
        File.delete(path_to_file) if File.exist?(path_to_file)
      end
      
    ######### END SIGN##############
    
    
    
    
    
    private
    def _random_string_(len)
        #chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
        newpass = ""
        #1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
        newpass = rand(999999).to_s.center(6, rand(len).to_s).to_i
        return newpass
      end
    private
    def _random_users_(len)
        #chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
        newpass = ""
        #1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
        newpass = rand(999999).to_s.center(6, rand(len).to_s).to_i
        return newpass
    end
    
    private
    def isEmailExt(str)
      return str.match('[a-z0-9]+[_a-z0-9\.-]*[a-z0-9]+@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,3})')
    end
    
end
