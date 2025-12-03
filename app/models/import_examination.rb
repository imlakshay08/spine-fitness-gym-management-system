class ImportExamination < ApplicationRecord
    def self.import(file)     
        $xcount      = 0
        $updatecount = 0
       if $isimport == 'employee'
         
        # spreadsheet = open_spreadsheet(file,:encoding => "Shift_JIS:UTF-8")
        # csv = File.read(file)
           # CSV.parse(csv, headers: true).each do |row|
           #   Item.create(row.to_h)
           # end
        #  header = Item.row(1)
       #   (2..spreadsheet.last_row).each do |i|
       #         row = Hash[[header, spreadsheet.row(i)].transpose]
       #quote_chars = %w(" | ~ ^ & * , / ')
              CSV.foreach(file.path,headers: true, external_encoding: "ISO8859-1", internal_encoding: "utf-8" ) do |row|
               compcode     =  (row["ie_compcode"].to_s.length >0 )? row["ie_compcode"] : '' 
               rollno       =  (row["ie_rollno"].to_s.length >0 )? row["ie_rollno"] : ''
               year         =  (row["ie_year"].to_s.length >0 )? (row["ie_year"]) : 0
               subject      =  (row["ie_subject"].to_s.length >0 )? (row["ie_subject"]) : 0
               marks        =  (row["ie_marks"].to_s.length >0 )? row["ie_marks"] : ''
               
                if $checkscaleupdate.to_s == 'Y' ####UPDATE SCALE
                     if fill_allowance_detail($compcodes,empcode,basic,hra,conv,da,otherall,otherall2,mis,bonexgratia,pfyesno,pfstartdate,pfno,esiyesno,esino,esistartdate)
                        $xcount +=1
                     end
                else
              ###### START IMPORT DATA OF EMPLOYEE ########## 
                    new_fill_allowance_detail($compcodes,empcode,basic,hra,conv,da,otherall,otherall2,mis,bonexgratia)
                   sewdobj = new_update_employee(empcode,names,dob,datejoining,department,designation,gender,empcontact,empemail,branch,presentaddress,presentphone,presentmobile,premanentaddress,permanentphone,permanentmobile,maritalstatus,pfyesno,pfstartdate,pfno,esiyesno,esistartdate,esino,catcode,qualfcode,pan,leaving_date,leave_reason,shift_code,ot_yesno,basic,hra,conv,da,otherall,so_uan,aadhar_no,account_no,bank_name,ifscode,vendorcode,fathername,bonexgratia)
                   if sewdobj             
                       $xcount +=1
                   end
               end
       end
     end
   
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
