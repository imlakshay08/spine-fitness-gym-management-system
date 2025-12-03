class StudentDataImport < ApplicationRecord
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
               name       =  (row["name"].to_s.length >0 )? mys_year_month_days_formatted(row["name"]) : 0
               dob        =  (row["dob"].to_s.length >0 )? row["dob"] : ''
               gender       =  (row["gender"].to_s.length >0 )? row["gender"] : ''          
               if gender !=nil && gender !='' && gender.to_s.downcase == 'male'
                   gender = "M" 
               elsif gender !=nil && gender !='' && gender.to_s.downcase == 'female'
                   gender = "F" 
               end
                if $checkscaleupdate.to_s == 'Y' ####UPDATE SCALE
                     if fill_allowance_detail($compcodes,empcode,basic,hra,conv,da,otherall,otherall2,mis,bonexgratia,pfyesno,pfstartdate,pfno,esiyesno,esino,esistartdate)
                        $xcount +=1
                     end
                else
              ###### START IMPORT DATA OF EMPLOYEE ########## 
                    # new_fill_allowance_detail($compcodes,empcode,basic,hra,conv,da,otherall,otherall2,mis,bonexgratia)
                   sewdobj = new_update_employee(reg_no,reg_date,name,dob,gender)
                   if sewdobj             
                       $xcount +=1
                   end
               end
       end
     end
   
   end
   
   def self.new_update_employee(reg_no,reg_date,name,dob,gender)
    compcode      = $compcodes
    mycounst      = 0
    name          = name !=nil && name !='' ? name.to_s.strip : ''
    dob          = dob !=nil && dob !='' ? mys_year_month_days_formatted(dob) : 0
    reg_date   = reg_date !=nil && reg_date!='' ? mys_year_month_days_formatted(reg_date) : 0  
    sw_gender     = ''
    if gender !=nil && gender !='' && gender.to_s.downcase == 'male'
        sw_gender = 'M'
    elsif gender !=nil && gender !='' && gender.to_s.downcase == 'female'
        sw_gender = 'F'
    else
        sw_gender = gender
    end 
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
          mycounst += 1
     else    
        seobjs  = MstStudent.new(:stdnt_compcode=>compcode,:stdnt_reg_no=>reg_no,:stdnt_reg_date=>reg_date,:stdnt_fname=>name,:stdnt_dob=>dob)
        seobjs.save
        # fill_kyc_2(compcode,empcode,pan,aadhar_no)
        # fill_bank_2(compcode,empcode,account_no,bank_name,ifscode)
        # fill_office_2(compcode,empcode,datejoining,department,designation,pfyesno,pfstartdate,pfno,esiyesno,esistartdate,esino,qualfcode,pan,leaving_date,ot_yesno,basic,hra,conv,da,otherall,so_uan,bonexgratia)
        # fill_personal_2(compcode,empcode,presentaddress,presentphone,presentmobile,premanentaddress,permanentphone,permanentmobile,empcontact,empemail)
        mycounst += 1
     end
     return mycounst
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
