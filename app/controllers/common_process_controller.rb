class CommonProcessController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    include ErpModule::Common
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:set_ent,:set_dct
    def index

    end

    def ajax_process
        if params[:identity].to_s == 'Y'
            get_marketwise_wd_list()
            return;
        elsif params[:identity].to_s == 'AD'
            get_address_wd_list()
            return;
        elsif params[:identity].to_s == 'ACTYPE'
            get_activitytpe_wd_list()
            return;
        end
    end

    def get_marketwise_wd_list
        isFlags     = false
        mid         = params[:markteid]
        chkgrpobj   = MstWdmaster.where("Ref_City_id=?",mid).order("WDName ASC")
        if chkgrpobj.length >0
            isFlags = true
        end

         respond_to do |format|
           format.json { render :json => { 'data'=>chkgrpobj, :status=>isFlags } }
        end

    end

    def get_address_wd_list
        isFlags     = false
        mid         = params[:wdid]
        address     = ""
        chkgrpobj   = MstWdmaster.select("Address_1,Address_2,Address_3").where("Id=?",mid).first
        if chkgrpobj
            isFlags = true
            address = chkgrpobj.Address_1
            if chkgrpobj.Address_2.to_s.present?
                address +", "+chkgrpobj.Address_2.to_s    
            end
            if chkgrpobj.Address_3.to_s.present?
                address +", "+chkgrpobj.Address_3.to_s    
            end
        end

         respond_to do |format|
           format.json { render :json => { 'data'=>address, :status=>isFlags } }
        end

    end

    def get_activitytpe_wd_list
        isFlags     = false
        mid         = params[:wdid]
        address     = ""
        chkgrpobj   = MstActivity.where("Id=?",mid).first
        if chkgrpobj
            isFlags = true
            address = chkgrpobj.activity_name
            
        end

         respond_to do |format|
           format.json { render :json => { 'data'=>address, :status=>isFlags } }
        end

    end

end
