class TimeTableController < ApplicationController
    before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date,:get_all_subjects,:get_timetable,:get_faculty,:get_all_faculty
     helper_method :get_faculty_timetable,:get_course_detail
    def index
        @compcodes      = session[:loggedUserCompCode] 
        @mydatas         = MstTimeTable.where("tt_compcode =? ", @compcodes)
        if params[:id].to_i>0
         # @time_table     = MstTimeTable.where("id=?",params[:id])
          mydata   = MstTimeTable.where("tt_compcode=? AND id=?",@compcodes, params[:id])
        end
        @time_table_list=get_time_table()
        @SubjectList    = MstSubjectList.where("sub_compcode =? AND sub_name != ''  ",@compcodes)
        @Faculty        = MstFaculty.where("fclty_compcode =? AND fclty_name != ''  ",@compcodes).order("fclty_name ASC")
        @CourseList     = MstCourseList.where("crse_compcode =? AND crse_code != ''  ",@compcodes)

    end

    def faculty_view
      @compcodes      = session[:loggedUserCompCode] 
      @faclt_id      = session[:facultyId]
      if session[:loginUserName] == 'adm' || session[:loginUserName]  == 'admin'
      @faculty=MstFaculty.where("fclty_compcode =? AND fclty_name != ''  ",@compcodes).order("fclty_name ASC")
      else
        @faculty=MstFaculty.where("fclty_compcode =? AND fclty_name != '' AND id = ? ",@compcodes,@faclt_id).order("fclty_name ASC")
      end
    end

    def ajax_process
        @compcodes       = session[:loggedUserCompCode]
        if params[:identity] != nil && params[:identity] != '' && params[:identity] == 'TIMETABLE'
            save_timetable();
            return
        elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'VWTIMETABLE'
          get_time_table_subject_year_wise()
          return    
        elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'FACULTYIMETABLE'
          get_faculty_time_table_year_wise()
          return
        elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'COURSESUBJECTS'
          get_subjects_on_course()
          return
        elsif params[:identity]!=nil && params[:identity]!= '' && params[:identity] == 'SUBJECT'
            get_subject_details()
            return
        elsif params[:identity]!=nil && params[:identity]!= '' && params[:identity] == 'DELTIMESHEET'
            delete_time_table_from_list()
            return
        elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'BRINGDATE'
            bring_from_upto_date();
            return
        end

        
        
    end

    def save_timetable
        compcodes    = session[:loggedUserCompCode]
        year         = params[:tt_year]
        qltype       = params[:tt_day]
        tt_subject   = params[:tt_subject].to_s.present? ? params[:tt_subject] : 0
        group        = params[:tt_group].to_s.present? ? params[:tt_group] : 0
        timetableid  = params[:timetableid] !=nil && params[:timetableid] !='' ? params[:timetableid] : 0
        course       = params[:tt_course].to_s.present? ? params[:tt_course] : 0
        sub_semster      = params[:sub_sem].to_s.present? ? params[:sub_sem] : 0

        isFlags      = true
        message      = ""
        if params[:tt_year].to_s.blank?
              message   = "Year is required."
              isFlags   = false
        elsif params[:tt_course].to_s.blank?
              message   = "Course is required."
              isFlags   = false  
        elsif params[:sub_sem].to_s.blank?
              message   = "Subject is required."
              isFlags   = false          
        elsif params[:tt_subject].to_s.blank?
              message   = "Subject is required."
              isFlags   = false
        elsif params[:tt_day].to_s.blank?
              message   = "Day is required."
              isFlags   = false
        elsif params[:tt_period].to_s.blank?
              message   = "Period is required."
              isFlags   = false
        elsif params[:tt_faculty].to_s.blank?
              message   = "Faculty is required."
              isFlags   = false
        elsif params[:tt_group].to_s.blank?
              message   = "Group is required."
              isFlags   = false
        
        end

        if  isFlags
              procescount =  process_timetable(year)
              if procescount.to_i >0
                  isFlags = true
                  if timetableid.to_i >0
                      message = "Data updated sucessfully"
                  else
                      message = "Data saved sucessfully"
                  end
  
              else
                    message = "A subject is already scheduled in this period."
              end
        end
        timetable = get_group_timetable_information(compcodes,year,course,sub_semster) 
        vhtml     = render_to_string :template  => 'time_table/subject_faculty_list',:layout => false, :locals => { :mydata => timetable,:year=>year,:subject=>tt_subject,:group=>group,:sub_semster=>sub_semster,:course=>course}
        respond_to do |format|
          format.json { render :json => { 'data'=>vhtml,"message"=>message,:status=>isFlags} }
        end
    end

    def get_subjects_on_course
      compcodes = session[:loggedUserCompCode]
      course_id = params[:course_id].to_i >0 ? params[:course_id].to_i : 0
      sub_sem   = params[:sub_sem].to_i >0 ? params[:sub_sem].to_i : 0
      # Fetch subjects related to the selected course
      if course_id > 0
        @subjects = MstSubjectList.where("sub_compcode = ? AND sub_crse = ? AND sub_sem = ?", compcodes, course_id,sub_sem)
      else
        @subjects = []
      end
    
      render json: { subjects: @subjects }
    end
    

    def get_time_table_subject_year_wise
      compcodes    = session[:loggedUserCompCode]
      year         = params[:tt_year].to_s.present? ?  params[:tt_year] : 0   
      subject      = params[:tt_subject].to_s.present? ? params[:tt_subject] : 0
      group        = params[:tt_group].to_s.present? ? params[:tt_group] : 0
      course       = params[:tt_course].to_s.present? ? params[:tt_course] : 0
      sub_semster  = params[:sub_semster].to_s.present? ? params[:sub_semster] : 0
      isFlags      = false
      timetable    = get_group_timetable_information(compcodes,year,course,sub_semster)
      if timetable.length >0
         isFlags = true
      end
      vhtml   = render_to_string :template  => 'time_table/subject_faculty_list',:layout => false, :locals => { :mydata => timetable,:year=>year,:subject=>subject,:group=>group,:sub_semster=>sub_semster,:course=>course}
      respond_to do |format|
        format.json { render :json => { 'data'=>vhtml,:status=>isFlags} }
      end

    end

    def get_faculty_time_table_year_wise
      compcodes    = session[:loggedUserCompCode]
      year         = params[:tt_year].to_s.present? ?  params[:tt_year] : 0   
      faculty      = params[:tt_faculty].to_s.present? ? params[:tt_faculty] : 0

      isFlags      = false
      timetable    = get_faculty_timetable_information(compcodes,year,faculty)
      if timetable.length >0
         isFlags = true
      end
      vhtml   = render_to_string :template  => 'time_table/view_faculty_list',:layout => false, :locals => { :mydata => timetable,:year=>year,:faculty=>faculty,:subject=>0}
      respond_to do |format|
        format.json { render :json => { 'data'=>vhtml,:status=>isFlags} }
      end

    end

    def get_time_table
      @compcodes      = session[:loggedUserCompCode] 
      if params[:page].to_i >0
          pages = params[:page]
      else
          pages = 1
      end
        # if params[:server_request]!=nil && params[:server_request]!= ''

           session[:req_tt_subject] = nil
        # end
        filter_search = params[:tt_subject] !=nil && params[:tt_subject] != '' ? params[:tt_subject].to_s.strip : session[:req_tt_subject].to_s.strip       
        iswhere       = "tt_compcode ='#{@compcodes}'"
        if filter_search !=nil && filter_search !=''
          iswhere +=" AND ( tt_year LIKE '%#{filter_search}%' OR tt_subject LIKE '%#{filter_search}%')"
          @tt_subject       = filter_search
          session[:req_tt_subject] = filter_search
        end    
      stdob =  MstTimeTable.where(iswhere).order("id ASC")
      return stdob
    end

    def process_timetable(tt_year)
      compcodes      = session[:loggedUserCompCode] 
      tt_year        = params[:tt_year] !=nil && params[:tt_year]!='' ? params[:tt_year] : ''
      tt_day         = params[:tt_day] !=nil && params[:tt_day] !='' ? params[:tt_day] : ''
      tt_period      = params[:tt_period] !=nil && params[:tt_period] !='' ? params[:tt_period] : ''
      tt_subject     = params[:tt_subject] !=nil && params[:tt_subject] !='' ? params[:tt_subject] : ''
      tt_faculty     = params[:tt_faculty] !=nil && params[:tt_faculty] !='' ? params[:tt_faculty] : ''
      tt_group       = params[:tt_group] !=nil && params[:tt_group] !='' ? params[:tt_group] : ''
      timetableid    = params[:timetableid] !=nil && params[:timetableid] !='' ? params[:timetableid] : 0
      tt_course      = params[:tt_course].to_s.present? ?  params[:tt_course].to_s : 0
      sub_sem        = params[:sub_sem].to_s.present? ?  params[:sub_sem].to_s : 0
      counts         = 0;
      iswhere  = "tt_compcode='#{compcodes}' AND tt_day='#{tt_day}' AND tt_period='#{tt_period}' AND tt_year='#{tt_year}'"
      
      if tt_course.to_i>0
        iswhere  += " AND tt_course='#{tt_course}'"
      end
      if sub_sem.to_i>0
        iswhere  += " AND tt_semester='#{sub_sem}'"
      end
      if tt_group.to_s.present?
        iswhere  += " AND tt_group='#{tt_group}'"
      end

      # if tt_subject.to_s.present?
      #   iswhere  += " AND tt_subject='#{tt_subject}'"
      # end
       if tt_faculty.to_s.present?
         iswhere  += " AND tt_faculty='#{tt_faculty}'"
       end

      

        timeobj = MstTimeTable.where(iswhere)
        if timeobj.length >0
            return 0
        end        
        if tt_year !=nil && tt_year !=''
            process_save_qualification(compcodes,tt_year,tt_day,tt_period,tt_subject,tt_faculty,tt_group,timetableid,tt_course,sub_sem)
            counts = 1;
        end
        return counts;
    end

    def process_save_qualification(tt_compcode,tt_year,tt_day,tt_period,tt_subject,tt_faculty,tt_group,timetableid,tt_course,sub_sem)
      mygroup = get_group_check_detail(tt_period,tt_group)
      adgroup = ''
      if mygroup.to_s.present?
          adgroup = mygroup.to_s.strip
      end      
      mstseuobj  = MstTimeTable.where("tt_compcode =? AND id = ?",tt_compcode,timetableid).first
      if mstseuobj
            mstseuobj.update(:tt_semester=>sub_sem,:tt_course=>tt_course,:tt_addional_group=>adgroup,:tt_year=>tt_year,:tt_day=>tt_day,:tt_period=>tt_period,:tt_subject=>tt_subject,:tt_faculty=>tt_faculty,:tt_group=>tt_group)
            ## execute message if required
      else
            mstsvqlobj = MstTimeTable.new(:tt_compcode=>tt_compcode,:tt_semester=>sub_sem,:tt_course=>tt_course,:tt_addional_group=>adgroup,:tt_year=>tt_year,:tt_day=>tt_day,:tt_period=>tt_period,:tt_subject=>tt_subject,:tt_faculty=>tt_faculty,:tt_group=>tt_group)
            if mstsvqlobj.save
                ## execute message if required
            end
      end

    end

    def get_all_subjects(subjectid)
      @compcodes      = session[:loggedUserCompCode] 
      catobjs  = MstSubjectList.where("sub_compcode=? AND id=?", @compcodes,subjectid).first
      return catobjs
    end

    def get_all_faculty(facultyid)
      @compcodes= session[:loggedUserCompCode] 
      catobjs   = MstFaculty.where("fclty_compcode=? AND id=?", @compcodes,facultyid).first
      return catobjs
    end

    def get_faculty(days,period,year=0,subject=0,group)
      @compcodes = session[:loggedUserCompCode] 
      facultyname=""
      facultyobj =[]
      timetableob= MstTimeTable.where("tt_day=? AND tt_period=? AND tt_year =? AND tt_subject = ? AND tt_group",days,period,year,subject,group).first
      if timetableob
        facultyobj=get_all_faculty(timetableob.tt_faculty)
        if facultyobj
          facultyname = facultyobj.fclty_name
        end
      end
      return facultyname
    end

    def get_timetable(days,period,year,subject,group,sub_semster='',course)
      @compcodes  = session[:loggedUserCompCode]     
      allcontent  = ""
      subjectobj  = []
      newgroup    = ''
      if group.to_s.present?
          if group.to_s=='A' || group.to_s =='1'
              newgroup = "'A','1'"
          elsif group.to_s=='B' || group.to_s =='2'
              newgroup = "'B','2'"
          elsif group.to_s=='C' || group.to_s =='3'
              newgroup = "'C','3'"
          elsif group.to_s=='D' || group.to_s =='4'
              newgroup = "'D','4'"
          elsif group.to_s=='E' || group.to_s =='5'
              newgroup = "'E','5'"
          elsif group.to_s=='F' || group.to_s =='6'
              newgroup = "'F','6'"
          elsif group.to_s=='G' || group.to_s =='7'
              newgroup = "'G','7'"
          elsif group.to_s=='H' || group.to_s =='8'
              newgroup = "'H','8'"
          end
      end
      timetableob = MstTimeTable.where("tt_day=? AND tt_period=? AND tt_year =? AND tt_group IN(#{newgroup}) AND tt_semester =? AND tt_course = ?",days,period,year,sub_semster,course)   #AND tt_subject = ? 
      if timetableob.length >0
            timetableob.each do |newlist|
                  subjectobj = get_all_subjects(newlist.tt_subject)
                  facultyobj = get_all_faculty(newlist.tt_faculty)
                    subjectname = ""
                    subjcode    = ""
                  if subjectobj
                    subjcode    = subjectobj.sub_code
                    subjectname = subjectobj.sub_name
                  end
                  if facultyobj
                    facultyname = facultyobj.fclty_name
                  end
                  allcontent += facultyname.to_s+" - "+subjcode.to_s+"<br/>" #+= subjcode.to_s+" - "+subjectname.to_s+ " => "+facultyname.to_s+" ,<br/>"
            end
            
      end
      return allcontent
    end

    def get_group_check_detail(period,group)
      mygroup = ''
      if ( period.to_i == 1 || period.to_i == 2 || period.to_i == 3 || period.to_i == 4 ) && group.to_s =='A'
           mygroup = 1
      elsif ( period.to_i == 1 || period.to_i == 2 || period.to_i == 3 || period.to_i == 4 )  && group.to_s =='B'
          mygroup = 2
      elsif ( period.to_i == 1 || period.to_i == 2 || period.to_i == 3 || period.to_i == 4 )  && group.to_s =='C'
          mygroup = 3
      elsif ( period.to_i == 1 || period.to_i == 2 || period.to_i == 3 || period.to_i == 4 )  && group.to_s =='D'
           mygroup = 4      
      end
        return mygroup
    end

    def check_addition_group()
      timetableob= MstTimeTable.where("tt_day=? AND tt_period=? AND tt_year =? AND tt_group =?",days,period,year,group)
    end

    def get_faculty_timetable(days,period,year,faculty)
      @compcodes  = session[:loggedUserCompCode] 
      subjectname = ""
      subnames    = ""
      subjectobj  = []
      jons        = ""
      timetableob = MstTimeTable.where("tt_day=? AND tt_period=? AND tt_year =? AND tt_faculty = ?",days,period,year,faculty).first
      if timetableob
            subjectobj=get_all_subjects(timetableob.tt_subject)
            facultyobj=get_all_faculty(timetableob.tt_faculty)
            if subjectobj
              subjectname = subjectobj.sub_code
              subnames    = subjectobj.sub_name
            end
            if facultyobj
              facultyname = facultyobj.fclty_name
            end
      end
      if subjectname.to_s.present? && subnames.to_s.present?
        jons = "#{subjectname} - #{subnames}" 
      elsif subjectname.to_s.present?
        jons = subjectname.to_s
      else
        jons = ""
      end
      return jons
    end

    private
    def get_subject_details
        compcodes      = session[:loggedUserCompCode] 
        requesttype = params[:requesttype]
        requestcode = params[:requestcode]
        requestname = params[:requestname]
        course      = params[:course]
        isFlags     = false
        semester   = []
        typ = []
      
        isselect   = "id,sub_name as subjectname,sub_code as subjectcode, sub_crse as course, sub_sem as semester, sub_type as typ"
        if requesttype.to_s == 'CODE'
          
              iswhere    = "sub_compcode='#{compcodes}' AND  id ='#{course}' "
             
              sewdobj    = MstSubjectList.select(isselect).where(iswhere).first
              if sewdobj.present?
                #course = sewdobj.sub_crse
                courses   = get_course_detail(course)
                
                isFlags = true
              end
        else
               iswhere    = "sub_compcode='#{compcodes}' AND sub_name LIKE '%#{requestname}%'"
               if course !=nil && course!=''
                iswhere += " AND UPPER(sub_crse)=UPPER('#{course}')"
              end
               sewdobj    = MstSubjectList.select(isselect).where(iswhere).order("sub_name ASC")
               if sewdobj.length>0
                  isFlags = true
                  sewdobj.each do |newloc|
                    
                    course   = get_course_detail(newloc.crse_code)
                    
                  end
               end
        end
            respond_to do |format|
              format.json { render :json => { 'data'=>sewdobj,'course'=>courses,'semester'=> semester, 'typ'=>typ,:status=>isFlags} }
            end
    end

   def delete_time_table_from_list
    compcodes   = session[:loggedUserCompCode] 
    days        = params[:days]
    period      = params[:period]
    year        = params[:year]
    subject     = params[:subject]
    group       = params[:group]
    courses     = params[:courses]
    sub_semster       = params[:sub_semster]
    isFlags     = false
    message     = ""
    timetableob = MstTimeTable.where("tt_day=? AND tt_period=? AND tt_year =? AND tt_course =? AND tt_group =? AND tt_semester=?",days,period,year,courses,group,sub_semster)
    if timetableob.length >0
        if timetableob.destroy_all
            message = "Data deleted successfully."
            isFlags = true
        end
    else  
         message = "Mismatch data."    
    end

    respond_to do |format|
      format.json { render :json => { 'data'=>'',:message=>message,:status=>isFlags} }
    end


   end
    
  private
   def bring_from_upto_date
       @compcodes   = session[:loggedUserCompCode] 
       year         = params[:year]
       course       = params[:course]
       sem          = params[:semester]
       from_date    =""
       upto_date    =""
       message      =""
       timetabledtparam=[]
       isFlags = false

     
     if course.present? && sem.present?
       timetabledtparam = MstTimeTableDateParam.select("tt_dtp_fromdate,tt_dtp_uptodate").where("tt_dtp_compcode=? AND tt_dtp_year=? AND tt_dtp_course=? AND tt_dtp_sem=?",@compcodes,year,course,sem).first
       isFlags = true
       if timetabledtparam
         from_date = formatted_date(timetabledtparam.tt_dtp_fromdate)
         upto_date = formatted_date(timetabledtparam.tt_dtp_uptodate)
         isFlags = true
       end
      end
     
       respond_to do |format|
         format.json { render json: { 'data' => timetabledtparam,'from_date' => from_date, 'upto_date' => upto_date,'message' => '', status: isFlags } }
       end
   end
    
end
