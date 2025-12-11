class StockListController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    helper_method :check_existing_uses
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        @stock_list = get_stock_list()
        printPath     =  "stock_list/1_prt_stock_list.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'stock'
              
              @stockdetail   = print_stock_list()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = StockPdf.new(@stockdetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_stock_list.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def add_stock
        @compcodes      = session[:loggedUserCompCode] 
        @stock = nil
        if params[:id].to_i>0
            @stock= MstStockList.where("sl_compcode=? AND id=?",@compcodes,params[:id]).first
        end
    end

    def referesh_stock_list
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        session[:req_stock_list] = nil 
        isFlags = true
        redirect_to  "#{root_url}stock_list"
    end

    def create
        @compcodes      = session[:loggedUserCompCode] 
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:sl_name].to_s.downcase.blank?
           flash[:error] =  "Stock Name is Required"
           isFlags = false
        end
        if params[:sl_descp].to_s.downcase.blank?
          flash[:error] =  "Stock Description is Required"
          isFlags = false
       end
        currentgrp =  params[:cur_sl_name].to_s.strip
        newgroup   =  params[:sl_name].to_s.strip

        if params[:mid].to_i>0
            if currentgrp.to_s.downcase != newgroup.to_s.downcase
                chkgrpobj   = MstStockList.where("sl_compcode=? AND LOWER(sl_name)=? ",@compcodes,newgroup.to_s.downcase)
                if chkgrpobj.length>0
                    flash[:error] = "Could not be create duplicate Stock."
                    isFlags        = false
                end
            end
    
          if isFlags
                chkgrpobj   = MstStockList.where("sl_compcode=? AND id=?",@compcodes,mid).first
                if chkgrpobj
                    chkgrpobj.update(stock_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                    modulename = "Stock List"
                    description = "Stock List Update: #{params[:sl_name]}"
                    process_request_log_data("UPDATE", modulename, description)
                end
          end
        else
            chkgrpobj   = MstStockList.where("sl_compcode=? AND LOWER(sl_name)=?",@compcodes,newgroup.to_s.downcase)
            if chkgrpobj.length>0
              flash[:error] = "Could not be create duplicate Stock."
             isFlags        = false
            end
              if isFlags
                  savegrp = MstStockList.new(stock_params)
                  if savegrp.save
                      flash[:error] = "Data saved successfully"
                      isFlags       = true
                      modulename = "Stock List"
                      description = "Stock List Save: #{params[:sl_name]}"
                      process_request_log_data("SAVE", modulename, description)
                 
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
            isFlags = false
        end
        if isFlags
            redirect_to  "#{root_url}stock_list"
        else
            if params[:mid].to_i>0 
                redirect_to  "#{root_url}stock_list/add_stock/"+params[:mid].to_s
            else
                redirect_to  "#{root_url}stock_list/add_stock"
            end
              
        end
    
    end

    def destroy
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i >0
            @ListSate =  MstStockList.where("sl_compcode=? AND id=?", @compcodes,params[:id].to_i).first
            if @ListSate
                chekobj =  check_existing_uses(@ListSate.id)
                if chekobj                   
                    flash[:error] =  "Sorry !! The Selected Stock could not be deleted as it is being used in Stock Transaction."
                    isFlags       =  true
                    session[:isErrorhandled] = 1
                else @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
            end
       end
       redirect_to "#{root_url}stock_list"
    end

    private
    def get_stock_list
        @compcodes      = session[:loggedUserCompCode] 
        if params[:page].to_i >0
            pages = params[:page]
            else
            pages = 1
            end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
            #  session[:req_category_list] = nil
          # end
          filter_search = params[:stock_list] !=nil && params[:stock_list] != '' ? params[:stock_list].to_s.strip : session[:req_stock_list].to_s.strip       
          iswhere       = "sl_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( sl_name LIKE '%#{filter_search}%' OR sl_descp LIKE '%#{filter_search}%')"
            @stock_list_search       = filter_search
            session[:req_stock_list] = filter_search
          end     
        
          stdob =  MstStockList.where(iswhere).order("sl_name ASC")
          return stdob

    end

    def print_stock_list
        @compcodes      = session[:loggedUserCompCode] 
        iswhere         = "sl_compcode ='#{@compcodes}'"
        filter_search   = session[:req_stock_list]   
        if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( sl_name LIKE '%#{filter_search}%' OR sl_descp LIKE '%#{filter_search}%')"
          end    
        stdob =  MstStockList.where(iswhere).order("sl_name ASC")
        return stdob
    end

    private
    def stock_params
        @compcodes      = session[:loggedUserCompCode] 
        params[:sl_compcode]	    = @compcodes
        params.permit(:sl_compcode,:sl_name,:sl_descp)
    end

    private
    def check_existing_uses(catcode)
        @compcodes = session[:loggedUserCompCode]
        sewobj = TrnStockInventory.where("si_compcode = ? AND si_stock_id = ?", @compcodes, catcode)
        sewobj.exists?
      end
end
