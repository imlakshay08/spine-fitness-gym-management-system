class FeeListController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    helper_method :get_feelist
    def index
      @compcodes       = session[:loggedUserCompCode]
      @fee_list     = get_fee_list_index()
      if params[:id].to_i>0
        @fees_list     =MstFeeList.where("fee_compcode=? AND id=?", @compcodes,params[:id].to_i)
      end
      @CourseList       = MstCourseList.where("crse_compcode =? AND crse_code != ''  ",@compcodes)
    end

    def add_fee_structure
        @compcodes       = session[:loggedUserCompCode]
        @CourseList     = MstCourseList.where("crse_compcode =? AND crse_descp != ''  ",@compcodes)
        @CategoryList   = MstCategoryList.where("cat_compcode =? AND cat_descp != ''  ",@compcodes)
        @CurrencyList   = MstCurrency.where(["cc_compcode =?",@compcodes]) 
        @Listsemester = []
        @CourseList.each do |course|
          duration = course.crse_duration
          @Listsemester += get_semester_list(duration)
        end
        
        @Listsemester.uniq!
        @CompnentList            = MstComponentList.where("compt_compcode =? AND compt_descp != ''  ",@compcodes)
        @FeeList=nil
        if params[:id].to_i>0
            @FeeList      = MstFeeList.where("fee_compcode=? AND id=?", @compcodes,params[:id].to_i).first
            @selected_semester = @subject.sub_sem if @subject.present?            
        end
    end

    def ajax_process
        @compCodes  =  session[:loggedUserCompCode]
        if params[:identity] !=nil && params[:identity] !='' && params[:identity]=='FEES'
            save_fee_list();
            return
        elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'SEMESTER'
            get_semesters();
            return
        elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'FEESLIST'
            get_fee_list();
            return
          elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'FEESSEARCH'
            search_fee_list();
            return
        end
    end

    def referesh_fee_list
      compcodes = session[:loggedUserCompCode]
      session[:isErrorhandled] = nil
      session[:postedpamams]   = nil
      session[:req_course_search] = nil
      session[:req_year_search] = nil
      isFlags = true
      redirect_to "#{root_url}fee_list"
    end

    def create
    end

    def destroy
      @compcodes      = session[:loggedUserCompCode] 
      if params[:id].to_i >0
          @ListSate =  MstFeeList.where("fee_compcode=? AND id=?", @compcodes,params[:id].to_i).first
             if @ListSate
                   @ListSate.destroy
                       flash[:error] =  "Data deleted successfully."
                       isFlags       =  true
                       session[:isErrorhandled] = nil
               
             end
     end
     redirect_to "#{root_url}fee_list"
    end

    def get_feelist(component, semester, year, course)
      @compcodes = session[:loggedUserCompCode]
      
      feelistob = MstFeeList.where("fee_compt = ? AND fee_sem = ? AND fee_year = ? AND fee_crse = ?", component, semester, year, course).first
      
      if feelistob
        feelistob.fee_amt
      else
        ""
      end
    end
    
    
    def deletefee
      compcodes = session[:loggedUserCompCode]
      if params[:id].to_i >0
        delobj =  MstFeeList.where("fee_compcode=? AND id=?",compcodes,params[:id].to_i).first
        if delobj
           if delobj.destroy
             flash[:error] =  "Fee detail deleted successfully."
             session[:isErrorhandled] = nil
           end
        end
        redirect_to "#{root_url}fee_list/add_fee_structure/"+params[:id]
       end
    end

    private
    def search_fee_list
      compcodes = session[:loggedUserCompCode]
      year         = params[:year_search].to_s.present? ?  params[:year_search] : 0   
      course      = params[:course_search].to_s.present? ? params[:course_search] : 0

      isFlags      = false
      feesearch    = get_feelist_search(compcodes,year,course)
      if feesearch.length >0
         isFlags = true
      end
      vhtml   = render_to_string :template  => 'fee_list/view_fee_search_list',:layout => false, :locals => { :mydata => feesearch,:year=>year,:course=>course,:subject=>0}
      respond_to do |format|
        format.json { render :json => { 'data'=>vhtml,:status=>isFlags} }
      end

    end

    private 
    def get_fee_list_index
      @compcodes = session[:loggedUserCompCode]
      if params[:page].to_i >0
        pages = params[:page]
     else
        pages = 1
     end
         
        if params[:server_request]!=nil && params[:server_request]!= ''           
          session[:req_year_search] = nil
          session[:req_course_search] = nil
       end
       course_search = params[:course_search] !=nil && params[:course_search] != '' ? params[:course_search].to_s.strip : session[:req_course_search].to_s.strip       
      year_search = params[:year_search] !=nil && params[:year_search] != '' ? params[:year_search].to_s.strip : session[:req_year_search].to_s.strip       
       iswhere       = "fee_compcode ='#{@compcodes}'"        
       if year_search !=nil && year_search !=''
         iswhere +=" AND ( fee_year LIKE '%#{year_search}%' )"
           @year_search       = year_search
           session[:req_year_search] = year_search
       end    
       if course_search !=nil && course_search !=''
         iswhere +=" AND ( fee_crse LIKE '%#{course_search}%' )"
           session[:req_course_search] = course_search
           @course_search              = course_search
       end
         if course_search !=nil && course_search !='' 
            stdob =  MstFeeList.where(iswhere).order("fee_compt ASC")
         else
               stdob =  MstFeeList.where(iswhere).order("fee_compt ASC")
         end

     return stdob
    end

    private
    def save_fee_list
        compcodes = session[:loggedUserCompCode]
        course = params[:fee_crse]
        year   = params[:fee_year]
        category = params[:fee_catgry]
        currency = params[:fee_currncy]
        semester = params[:fee_sem]
        footerid  = params[:FeelsitId] !=nil && params[:FeelsitId] !='' ? params[:FeelsitId] : 0
        isFlags   = true
        message   = ""

         if isFlags
              
                      procescount =  process_qualification(course)
                      if procescount.to_i >0
                        isFlags = true
                        if footerid.to_i >0
                          message = "Data updated sucessfully"
                        else
                          message = "Data saved sucessfully"
                        end
          
                      else
                        message = "This Fee Detail Already exist!"
                      end
               
        end     
        @adfeelist = get_all_fee_information(compcodes, year, course, currency, semester)
      vhtml   = render_to_string :template  => 'fee_list/add_fee_list',:layout => false, :locals => { :mydata => @adfeelist}
      respond_to do |format|
        format.json { render :json => { 'data'=>vhtml,"message"=>message,:status=>isFlags} }
      end
    end

    private
    def get_fee_list
        compcode = session[:loggedUserCompCode]
        course = params[:fee_crse]
        year   = params[:fee_year]
        category = params[:fee_catgry]
        currency = params[:fee_currncy]
        semester = params[:fee_sem]
        isFlags = true
        message = ""
        vhtml = ""
      
        if compcode.nil?
          isFlags = false
          message = "Company code not found in session."
        elsif year.blank?
          isFlags = false
          message = "Year is missing."
        elsif course.blank?
          isFlags = false
          message = "Course is missing."
        else 
          @feelist = MstFeeList.where("fee_compcode = ? AND fee_year = ? AND fee_crse = ? AND fee_currncy=? AND fee_sem=?", compcode, year, course, currency, semester) 
          if @feelist.any?
            vhtml = render_to_string(template: 'fee_list/view_fee_list', layout: false, locals: { feelist: @feelist })
          else
            isFlags = false
            message = "No records found."
          end
        end
      
        render json: { 'data' => vhtml, 'status' => isFlags, 'message' => message }
    end

    private
    def get_semesters
        @compcodes = session[:loggedUserCompCode]
        fee_crse = params[:fee_crse]
        semesters = []
        isflags = false
    
        # Use crse_code instead of id
        course = MstCourseList.select("crse_duration").where("crse_compcode = ? AND id = ?", @compcodes, fee_crse).first
    
        if course
          duration = course.crse_duration
          case duration
          when '6 Months'
            semesters = [1]
            isflags = true
          when '1 Year'
            semesters = [1, 2]
            isflags = true
          when '2 Year'
            semesters = [1, 2, 3, 4]
            isflags = true
          when '3 Year'
            semesters = [1, 2, 3, 4, 5, 6]
            isflags = true
          else
            # Handle any unexpected cases
            semesters = []
            isflags = false
          end
        end
    
        respond_to do |format|
          format.json { render json: { 'data' => semesters, 'message' => '', status: isflags } }
        end
    end
    
    private
    def process_qualification(registraton)
       compcodes             = session[:loggedUserCompCode]
       fee_year          = params[:fee_year] !=nil && params[:fee_year]!='' ? params[:fee_year] : ''
       fee_crse   = params[:fee_crse] !=nil && params[:fee_crse] !='' ? params[:fee_crse] : ''
       fee_sem         = params[:fee_sem] !=nil && params[:fee_sem] !='' ? params[:fee_sem] : ''
       fee_compt       = params[:fee_compt] !=nil && params[:fee_compt] !='' ? params[:fee_compt] : ''
       fee_amt          = params[:fee_amt] !=nil && params[:fee_amt] !='' ? params[:fee_amt] : ''
       fee_catgry       = params[:fee_catgry] !=nil && params[:fee_catgry] !='' ? params[:fee_catgry] : ''
       fee_currncy      = params[:fee_currncy] !=nil && params[:fee_currncy] !='' ? params[:fee_currncy] : ''
       footerid              = params[:FeelsitId] !=nil && params[:FeelsitId] !='' ? params[:FeelsitId] : 0
       isFlags           = true
      message           = ""
       counts = 0;
      if isFlags
        existing_record = MstFeeList.where("fee_compcode = ? AND fee_year = ? AND fee_crse = ? AND fee_sem = ? AND fee_compt = ?", compcodes, fee_year, fee_crse, fee_sem, fee_compt).where("id != ?", footerid).count
  
        if existing_record > 0
           isFlags = false
           message = "A record with the same combination already exists."
        else
         if fee_year !=nil && fee_year !=''
             process_save_qualification(compcodes,fee_year,fee_crse,fee_sem,fee_compt,fee_amt,fee_currncy,footerid)
             counts = 1;
         end
        end
      end
         return counts;

  end

    private
    def process_save_qualification(fee_compcode,fee_year,fee_crse,fee_sem,fee_compt,fee_amt,fee_currncy,footerid)
        mstseuobj =   MstFeeList.where("fee_compcode =? AND id = ?",fee_compcode,footerid).first
        if mstseuobj
          mstseuobj.update(:fee_year=>fee_year,:fee_crse=>fee_crse,:fee_sem=>fee_sem,:fee_compt=>fee_compt,:fee_amt=>fee_amt,:fee_currncy=>fee_currncy)
            ## execute message if required
        else

            mstsvqlobj = MstFeeList.new(:fee_compcode=>fee_compcode,:fee_year=>fee_year,:fee_crse=>fee_crse,:fee_sem=>fee_sem,:fee_compt=>fee_compt,:fee_amt=>fee_amt,:fee_currncy=>fee_currncy)
            if mstsvqlobj.save
                ## execute message if required
            end
        end
    end

    
      def get_semester_list(duration)
        case duration
        when '6 Months'
          [1]
        when '1 Year'
          [1, 2]
        when '2 Year'
          [1, 2, 3, 4]
        when '3 Year'
          [1, 2, 3, 4, 5, 6]
        else
          []
        end
      end



end
