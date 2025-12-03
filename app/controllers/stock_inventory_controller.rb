class StockInventoryController < ApplicationController
    before_action      :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    helper_method :get_course_detail
    def index
        @compcodes      = session[:loggedUserCompCode] 
        month_number     =  Time.now.month
        month_begin      =  Date.new(Date.today.year, month_number)
        begdate          =  Date.parse(month_begin.to_s)
        @nbegindate      =  begdate.strftime('%d-%b-%Y')
        month_ending     =  month_begin.end_of_month
        endingDate       =  Date.parse(month_ending.to_s)
        @enddate         =  endingDate.strftime('%d-%b-%Y')	
        @compDetail    =  MstCompany.where(["cmp_companycode = ?", @compcodes]).first
        @stock_inventory = get_stock_inventory()
        @StockList = MstStockList.where(["sl_compcode =?",@compcodes]) 
        printPath     =  "stock_inventory/1_prt_stock_inventory.pdf"
        if params[:id] != nil && params[:id] != ''
            docsid  = params[:id].to_s.split("_")
            rooturl       = "#{root_url}"
            if  docsid[1] == 'prt' && docsid[2] == 'stock'
              
              @stockinventorydetail   = print_stock_inventory()
                  respond_to do |format|
                      format.html
                      format.pdf do
                         pdf = StockinventoryPdf.new(@stockinventorydetail, @compDetail, rooturl)
                         send_data pdf.render,:filename => "1_stock_inventory.pdf", :type => "application/pdf", :disposition => "inline"
                      end
                    end

                end
            end
    end

    def add_stock_inventory
        @compcodes      = session[:loggedUserCompCode]
        @Lastcode=generate_regularization_series
        @StockList = MstStockList.where(["sl_compcode =?",@compcodes])         
        @stockin = nil
        if params[:id].to_i>0
            @stockin = TrnStockInventory.where("si_compcode=? AND id=?",@compcodes,params[:id]).first
         end
    end

    def referesh_stock_iventory
        @compcodes      = session[:loggedUserCompCode] 
        session[:isErrorhandled] = nil
        session[:postedpamams]   = nil
        isFlags = true
        redirect_to  "#{root_url}stock_inventory"
    end

    def create
        @compcodes      = session[:loggedUserCompCode] 
        isFlags     = true
        mid         = params[:mid]
        begin
        if params[:si_entry_no].to_s.blank?
           flash[:error] =  "Entry No. is Required"
           isFlags = false
        end
        if params[:si_stock_id].to_s.blank?
          flash[:error] =  "Stock is Required"
          isFlags = false
        end
        if params[:si_trans_type].to_s.blank?
            flash[:error] =  "Trannsaction Type is Required"
            isFlags = false
        end
        if params[:si_quantity].to_s.blank?
            flash[:error] =  "Quantity is Required"
            isFlags = false
        end

        if params[:si_trans_type].to_s.upcase == "OUT"
            available = get_current_stock(params[:si_stock_id])
            if params[:si_quantity].to_i > available.to_i
                flash[:error] = "Not enough stock available. Current Stock: #{available}"
                isFlags = false
            end
        end
        currentgrp =  params[:cur_si_entry_no].to_s.strip
        newgroup   =  params[:si_entry_no].to_s.strip
    
        if params[:mid].to_i>0

            if currentgrp.to_s.downcase != newgroup.to_s.downcase
                chkgrpobj   = TrnStockInventory.where("si_compcode=? AND LOWER(si_entry_no)=? ",@compcodes,newgroup.to_s.downcase)
                if chkgrpobj.length>0
                    flash[:error] = "Could not create duplicate ."
                    isFlags        = false
                end
            end
    
          if isFlags
                chkgrpobj   = TrnStockInventory.where("si_compcode=? AND id=?",@compcodes,mid).first
                if chkgrpobj
                    chkgrpobj.update(stock_inventory_params)
                    flash[:error] = "Data updated successfully"
                    isFlags       = true
                    modulename = "Stock Inventory List"
                    description = "Stock Inventory List Save: #{params[:si_entry_no]}"
                    process_request_log_data("SAVE", modulename, description)
               
                end
          end
        else
            chkgrpobj   = TrnStockInventory.where("si_compcode=? AND LOWER(si_entry_no)=?",@compcodes,newgroup.to_s.downcase)
            if chkgrpobj.length>0
              flash[:error] = "Could not be create duplicate."
             isFlags        = false
            end
              if isFlags
                  savegrp = TrnStockInventory.new(stock_inventory_params)
                  if savegrp.save
                      flash[:error] = "Data saved successfully"
                      isFlags       = true
                      modulename = "Stock Inventory List"
                      description = "Stock Inventory List Update: #{params[:si_entry_no]}"
                      process_request_log_data("UPDATE", modulename, description)
                  end
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
            isFlags = false
        end
        if isFlags
            redirect_to  "#{root_url}stock_inventory"
        else
            if params[:mid].to_i>0 
                redirect_to  "#{root_url}stock_inventory/add_stock_inventory/"+params[:mid].to_s
            else
                redirect_to  "#{root_url}stock_inventory/add_stock_inventory"
            end
              
        end
    
    end

    def destroy
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i >0
            @ListSate =  TrnStockInventory.where("si_compcode=? AND id=?", @compcodes,params[:id].to_i).first
               if @ListSate
                     @ListSate.destroy
                         flash[:error] =  "Data deleted successfully."
                         isFlags       =  true
                         session[:isErrorhandled] = nil
                 
               end
       end
       redirect_to "#{root_url}stock_inventory"
    end

    private
    def get_stock_inventory
        @compcodes      = session[:loggedUserCompCode] 
        if params[:page].to_i >0
            pages = params[:page]
        else
            pages = 1
        end
            
          # if params[:server_request]!=nil && params[:server_request]!= ''
           
        session[:req_stock_inventory] = nil
        session[:req_stock_search] = nil
          # end
        filter_search = params[:stock_inventory] !=nil && params[:stock_inventory] != '' ? params[:stock_inventory].to_s.strip : session[:req_stock_inventory].to_s.strip       
        stock_search = params[:stock_search] !=nil && params[:stock_search] != '' ? params[:stock_search].to_s.strip : session[:req_stock_search].to_s.strip

          iswhere       = "si_compcode ='#{@compcodes}'"
          if filter_search !=nil && filter_search !=''
            iswhere +=" AND ( si_entry_no LIKE '%#{filter_search}%')"
            @stock_inventory_search       = filter_search
            session[:req_stock_inventory] = filter_search
          end    
          
          if stock_search !=nil && stock_search !=''
            iswhere +=" AND ( si_stock_id LIKE '%#{stock_search}%' )"
            @stock_search       = stock_search
            session[:req_stock_search] = stock_search
          end    
        
          stdob =  TrnStockInventory.where(iswhere).order("si_entry_no ASC")
          return stdob

    end

    private
    def stock_inventory_params
        @compcodes      = session[:loggedUserCompCode] 
        params[:si_compcode]	    = @compcodes
        params[:si_entry_date] = Date.today
        params.permit(:si_compcode,:si_entry_no,:si_entry_date,:si_stock_id,:si_trans_type,:si_quantity,:si_remarks)

    end

    private
    def generate_regularization_series
        @compcodes      = session[:loggedUserCompCode]
         @isCode     = 0
         @Startx     = '0000' 
         @recCodes  = TrnStockInventory.where(["si_compcode = ? AND si_entry_no <>'' ", @compcodes]).order('si_entry_no DESC').first
         if @recCodes
           @isCode    = @recCodes.si_entry_no.to_i
         end	  
           @sumXOfCode    = @isCode.to_i + 1
           if @sumXOfCode.to_s.length < 2
             @sumXOfCode = p @Startx.to_s + @sumXOfCode.to_s
           elsif @sumXOfCode.to_s.length < 3
             @sumXOfCode = p "000" + @sumXOfCode.to_s
           elsif @sumXOfCode.to_s.length < 4
             @sumXOfCode = p "00" + @sumXOfCode.to_s
           elsif @sumXOfCode.to_s.length < 5
             @sumXOfCode = p "0" + @sumXOfCode.to_s
           elsif @sumXOfCode.to_s.length >=5
             @sumXOfCode =  @sumXOfCode.to_i
           end
         return @sumXOfCode
    end

end
