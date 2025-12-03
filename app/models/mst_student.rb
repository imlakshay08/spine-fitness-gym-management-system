class MstStudent < ApplicationRecord
    require 'csv'

    def self.import(file)     
        $xcount      = 0
        $updatecount = 0
       if $isimport == 'employee'
         
        # spreadsheet = open_spreadsheet(file,:encoding => "Shift_JIS:UTF-8")
        # csv = File.read(file)
           # CSV.parse(csv, headers: true).each do |row|
           #   Item.create(row.to_h)
           # end
       #   header = Item.row(1)
       #   (2..spreadsheet.last_row).each do |i|
       #         row = Hash[[header, spreadsheet.row(i)].transpose]
       #quote_chars = %w(" | ~ ^ & * , / ')
              CSV.foreach(file.path,headers: true, external_encoding: "ISO8859-1", internal_encoding: "utf-8" ) do |row|
               reg_no                =  (row["reg_no"].to_s.length >0 )? row["reg_no"] : ''
               reg_date               =  (row["reg_date"].to_s.length >0 )? mys_year_month_days_formatted(row["reg_date"]) : 0
               dob       =  (row["dob"].to_s.length >0 )? mys_year_month_days_formatted(row["dob"]) : 0
               name        =  (row["name"].to_s.length >0 )? row["name"] : ''
               gender       =  (row["gender"].to_s.length >0 )? row["gender"] : ''
               blood_group       =  (row["blood_group"].to_s.length >0 )? row["blood_group"] : ''     
               if gender !=nil && gender !='' && gender.to_s.strip.downcase == 'male'
                   gender = "M" 
               elsif gender !=nil && gender !='' && gender.to_s.strip.downcase == 'female'
                   gender = "F" 
               end
               course       =  (row["course"].to_s.length >0 )? row["course"] : ''     
               category       =  (row["category"].to_s.length >0 )? row["category"] : ''     
               permanent_address       =  (row["permanent_address"].to_s.length >0 )? row["permanent_address"] : ''     
               present_address       =  (row["present_address"].to_s.length >0 )? row["present_address"] : ''     
               city       =  (row["city"].to_s.length >0 )? row["city"] : ''     
               nationality       =  (row["nationality"].to_s.length >0 )? row["nationality"] : ''     
               hostel       =  (row["hostel"].to_s.length >0 )? row["hostel"] : ''     
               aadhaar_no       =  (row["aadhaar_no"].to_s.length >0 )? row["aadhaar_no"] : ''     
               contact_no       =  (row["contact_no"].to_s.length >0 )? row["contact_no"] : ''     
               student_email       =  (row["student_email"].to_s.length >0 )? row["student_email"] : ''     
               bank_account_holder_name       =  (row["bank_account_holder_name"].to_s.length >0 )? row["bank_account_holder_name"] : ''     
               account_no       =  (row["account_no"].to_s.length >0 )? row["account_no"] : ''     
               ifsc_code       =  (row["ifsc_code"].to_s.length >0 )? row["ifsc_code"] : ''     
               course_type       =  (row["course_type"].to_s.length >0 )? row["course_type"] : ''
               fam_type       = ''
               father_name       =  (row["father_name"].to_s.length >0 )? row["father_name"] : ''     
               mother_name       =  (row["mother_name"].to_s.length >0 )? row["mother_name"] : ''     
               father_mobile       =  (row["father_mobile"].to_s.length >0 )? row["father_mobile"] : ''     
               mother_mobile       =  (row["mother_mobile"].to_s.length >0 )? row["mother_mobile"] : ''     
               father_email       =  (row["father_email"].to_s.length >0 )? row["father_email"] : ''     
               mother_email       =  (row["mother_email"].to_s.length >0 )? row["mother_email"] : ''     
               nhcm_no       =  (row["nhcm_no"].to_s.length >0 )? row["nhcm_no"] : ''     
               theory_group       =  (row["theory_group"].to_s.length >0 )? row["theory_group"] : ''     
               practical_group       =  (row["practical_group"].to_s.length >0 )? row["practical_group"] : ''     
               abc_id       =  (row["abc_id"].to_s.length >0 )? row["abc_id"] : ''
               student_status       =  (row["student_status"].to_s.length >0 )? row["student_status"] : ''
               if student_status.to_s.present? || student_status.to_s.blank?
                  student_status = "A" 
               end 
               semester       =  (row["semester"].to_s.length >0 )? row["semester"] : ''              
               ai_rank       =  (row["ai_rank"].to_s.length >0 )? row["ai_rank"] : ''     
               jnu_ignou_no       =  (row["jnu_ignou_no"].to_s.length >0 )? row["jnu_ignou_no"] : ''

                if $checkscaleupdate.to_s == 'UPDATE' ####UPDATE SCALE
                    sewdobj = update_groups($compcodes,reg_no,theory_group,practical_group)
                    if sewdobj             
                        $xcount +=1
                    end
                else
              ###### START IMPORT DATA OF EMPLOYEE ########## 
                    # new_fill_allowance_detail($compcodes,empcode,basic,hra,conv,da,otherall,otherall2,mis,bonexgratia)
                   sewdobj = new_update_employee(reg_no,reg_date,name,dob,gender,blood_group,course,category,permanent_address,present_address,city,nationality,hostel,aadhaar_no,contact_no,student_email,bank_account_holder_name,account_no,ifsc_code,course_type,fam_type,father_name,mother_name,father_mobile,mother_mobile,father_email,mother_email,nhcm_no,theory_group,practical_group,abc_id,ai_rank,jnu_ignou_no,student_status,semester)
                   if sewdobj             
                       $xcount +=1
                   end
               end
       end
     end
   
   end
   
   def self.new_update_employee(reg_no,reg_date,name,dob,gender,blood_group,course,category,permanent_address,present_address,city,nationality,hostel,aadhaar_no,contact_no,student_email,bank_account_holder_name,account_no,ifsc_code,course_type,fam_type,father_name,mother_name,father_mobile,mother_mobile,father_email,mother_email,nhcm_no,theory_group,practical_group,abc_id,ai_rank,jnu_ignou_no,student_status,semester)
    compcode      = $compcodes
    mycounst      = 0
    name          = name !=nil && name !='' ? name.to_s.strip : ''
    dob          = dob !=nil && dob !='' ? mys_year_month_days_formatted(dob) : 0
    reg_date   = reg_date !=nil && reg_date!='' ? mys_year_month_days_formatted(reg_date) : 0  
 
    maritalstatus = maritalstatus.to_s.strip ? maritalstatus.to_s.strip : ''
    if maritalstatus.to_s.downcase == 'married' 
      xmaritalstatus = "Y"
    elsif maritalstatus.to_s.downcase == 'unmarried'
      xmaritalstatus = "N"
    else
      xmaritalstatus = maritalstatus
    end
  #so_uan,aadhar_no, 
     seobjs = MstStudent.where("stdnt_compcode =? AND stdnt_reg_no = ?",compcode,reg_no).first
     if seobjs
          #### Execute if required
        seobjs.update(:stdnt_gender=>gender)
        fill_student_details(compcode,reg_no,course,category,permanent_address,present_address,city,nationality,hostel,aadhaar_no,contact_no,student_email,bank_account_holder_name,account_no,ifsc_code,course_type)
        fill_student_general_detail(compcode,reg_no,nhcm_no,theory_group,practical_group,abc_id,ai_rank,jnu_ignou_no,student_status,semester)
          mycounst += 1
     else    
        seobjs  = MstStudent.new(:stdnt_compcode=>compcode,:stdnt_reg_no=>reg_no,:stdnt_reg_date=>reg_date,:stdnt_fname=>name,:stdnt_dob=>dob,:stdnt_gender=>gender,:stdnt_bloodgroup=>blood_group)
        seobjs.save
        fill_student_details(compcode,reg_no,course,category,permanent_address,present_address,city,nationality,hostel,aadhaar_no,contact_no,student_email,bank_account_holder_name,account_no,ifsc_code,course_type)
        fill_student_family(compcode,reg_no,fam_type,father_name,mother_name,father_mobile,mother_mobile,father_email,mother_email,permanent_address)
        fill_student_general_detail(compcode,reg_no,nhcm_no,theory_group,practical_group,abc_id,ai_rank,jnu_ignou_no,student_status,semester)
        # fill_personal_2(compcode,empcode,presentaddress,presentphone,presentmobile,premanentaddress,permanentphone,permanentmobile,empcontact,empemail)
        mycounst += 1
     end
     return mycounst
  end

  def self.fill_student_details(compcode,reg_no,course,category,permanent_address,present_address,city,nationality,hostel,aadhaar_no,contact_no,student_email,bank_account_holder_name,account_no,ifsc_code,course_type)
    normalized_course = course.to_s.strip.downcase
    normalized_category = category.to_s.strip.downcase 
  # Map courses to codes
  xcourse = case normalized_course
  when 'b.sc.(hha)' then "13"
  when 'db&c' then "10"
  when 'df&bs' then "11"
  when 'dfp' then "9"
  when 'm.sc.(ha)' then "12"
  else course
  end

# Map categories to codes (if category is provided)
xcategory = case normalized_category
    when 'ews' then "12"
    when 'ews pd' then "13"
    when 'km' then "16"
    when 'nri' then "15"
    when 'nri-saarc' then "14"
    when 'obc' then "11"
    when 'obc pd' then "6"
    when 'open' then "3"
    when 'oppd' then "8"
    when 'sc' then "9"
    when 'sc pd' then "5"
    when 'st' then "10"
    when 'st pd' then "4"
    else category
    end if category

    nationality = nationality.to_s.strip ? nationality.to_s.strip : ''
    if nationality.to_s.strip.downcase == 'Indian' 
      xnationality = "I"
    elsif nationality.to_s.strip.downcase == 'Other'
      xnationality = "O"
    else
      xnationality = nationality
    end

    hostel = hostel.to_s.strip ? hostel.to_s.strip : ''
    if hostel.to_s.downcase == 'Yes' 
      xhostel = "Y"
    elsif hostel.to_s.downcase == 'No'
      xhostel = "N"
    else
      xhostel = hostel
    end

    course_type = course_type.to_s.strip ? course_type.to_s.strip : ''
    if course_type.to_s.downcase == 'Generic' 
      xcourse_type = "Generic"
    elsif course_type.to_s.downcase == 'Veg'
      xcourse_type = "Veg"
    elsif course_type.to_s.downcase == 'Non-Veg'
      xcourse_type = "Non-Veg"
    else
      xcourse_type = course_type
    end

    kycobj = MstStudentDtl.where("stdnt_dtl_compcode =? AND stdnt_dtl_code = ?",compcode,reg_no).first
    if kycobj
        #### UPDATE EXISTING DETAIL
        kycobj.update(:stdnt_dtl_aadhaar=>aadhaar_no,:stdnt_dtl_cont=>contact_no)
    else
        #### INSERT NEW DETAILS
        kycobj = MstStudentDtl.new(:stdnt_dtl_compcode=>compcode,:stdnt_dtl_code=>reg_no,:stdnt_dtl_crse=>xcourse,:stdnt_dtl_cat=>xcategory,
                                   :stdnt_dtl_add1=>permanent_address,:stdnt_dtl_add2=>present_address,:stdnt_dtl_city=>city,:stdnt_dtl_nat=>xnationality,
                                   :stdnt_dtl_hstl=>xhostel,:stdnt_dtl_aadhaar=>aadhaar_no,:stdnt_dtl_cont=>contact_no,:stdnt_dtl_email=>student_email,
                                   :stdnt_dtl_acc=>account_no,:stdnt_dtl_ifsc=>ifsc_code,:stdnt_dtl_acctholder=>bank_account_holder_name,:stdnt_dtl_typecourse=>xcourse_type)
        kycobj.save
    end
end

  def self.fill_student_family(compcode,reg_no,fam_type,father_name,mother_name,father_mobile,mother_mobile,father_email,mother_email,permanent_address)
    if father_name.to_s != nil && father_name.to_s != ""
      kycobj =  MstStdntFamily.new(:stdnt_fam_compcode=>compcode,:stdnt_fam_code=>reg_no,:stdnt_fam_type=>"Father",:stdnt_fam_father=>father_name,:stdnt_fam_tel_res=>father_mobile,:stdnt_fam_email=>father_email,:stdnt_fam_add1=>permanent_address)
      kycobj.save
      if mother_name.to_s != nil && mother_name.to_s != ""
      kycobj =  MstStdntFamily.new(:stdnt_fam_compcode=>compcode,:stdnt_fam_code=>reg_no,:stdnt_fam_type=>"Mother",:stdnt_fam_father=>mother_name,:stdnt_fam_tel_res=>mother_mobile,:stdnt_fam_email=>mother_email,:stdnt_fam_add1=>permanent_address)
      kycobj.save
      end
    end
  end

  def self.fill_student_general_detail(compcode,reg_no,nhcm_no,theory_group,practical_group,abc_id,ai_rank,jnu_ignou_no,student_status,semester)
    kycobj = MstStdntGenDtl.where("stdnt_gn_compcode = ? AND stdnt_gn_code = ?",compcode,reg_no).first
    if kycobj
       kycobj.update(:stdnt_gn_abc_id=>abc_id)
    else
      kycobj = MstStdntGenDtl.new(:stdnt_gn_compcode=>compcode,:stdnt_gn_code=>reg_no,:stdnt_gn_nhmc=>nhcm_no,:stdnt_gn_thry_grp=>theory_group,:stdnt_gn_prac=>practical_group,:stdnt_gn_abc_id=>abc_id,:stdnt_gn_rank=>ai_rank,:stdnt_gn_jnu_ignou=>jnu_ignou_no,:stdnt_gn_status=>student_status,:stdnt_gn_cur_sem=>semester)
      kycobj.save
    end
 end

  def self.update_groups(compcode,reg_no,theory_group,practical_group)
  updobj = MstStdntGenDtl.where("stdnt_gn_compcode = ? AND stdnt_gn_code = ?",compcode,reg_no).first
  if updobj
       updobj.update(:stdnt_gn_thry_grp=>theory_group,:stdnt_gn_prac=>practical_group)
  end
  end

  def self.mys_year_month_days_formatted(datess)
    newdate = ''
    dates   = datess.to_s.strip
    if dates!=nil && dates !='' && dates.to_s.length >3
          dts     = Date.parse(dates.to_s)
          newdate = dts.strftime("%Y-%m-%d")
    end
    return newdate
end
   def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Roo::CSV.new(file.path, :packed=> nil, :file_warning=> :ignore)
    when ".xls" then Roo::Excel.new(file.path, :packed=> nil, :file_warning=> :ignore)
    when ".xlsx" then Roo::Excelx.new(file.path, :packed=> nil, :file_warning=> :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
  
end
