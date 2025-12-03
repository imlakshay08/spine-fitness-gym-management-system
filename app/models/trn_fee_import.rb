class TrnFeeImport < ApplicationRecord
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
               biller_id                =  (row["Biller Id"].to_s.length >0 )? row["Biller Id"] : ''
               bank_id                  =  (row["Bank Id"].to_s.length >0 )? row["Bank Id"] : ''
               bankrefno                =  (row["Bank Ref. No."].to_s.length >0 )? row["Bank Ref. No."] : ''
               pgirefno                 =  (row["PGI Ref. No."].to_s.length >0 )? row["PGI Ref. No."] : ''
               ref1                     =  (row["Ref. 1"].to_s.length >0 )? row["Ref. 1"] : ''
               ref2                     =  (row["Ref. 2"].to_s.length >0 )? row["Ref. 2"] : ''     
               ref3                     =  (row["Ref. 3"].to_s.length >0 )? row["Ref. 3"] : ''     
               ref4                     =  (row["Ref. 4"].to_s.strip.downcase.length >0 )? row["Ref. 4"].to_s.strip.downcase : ''     
               ref5                     =  (row["Ref. 5"].to_s.length >0 )? row["Ref. 5"] : ''     
               ref6                     =  (row["Ref. 6"].to_s.length >0 )? row["Ref. 6"] : ''     
               ref7                     =  (row["Ref. 7"].to_s.length >0 )? row["Ref. 7"] : ''     
               ref8                     =  (row["Ref. 8"].to_s.strip.downcase.length >0 )? row["Ref. 8"].to_s.strip.downcase : ''     
               date_txn                 =  (row["Date of Txn"].to_s.length >0 )? row["Date of Txn"] : ''     
               settle_date              =  (row["Settlement Date"].to_s.length >0 )? row["Settlement Date"] : ''     
               gross_amount             =  (row["Gross Amount(Rs.Ps)"].to_s.length >0 )? row["Gross Amount(Rs.Ps)"] : ''     
               charges                  =  (row["Charges (Rs.Ps)"].to_s.length >0 )? row["Charges (Rs.Ps)"] : ''     
               gst                      =  (row["GST (Rs Ps)"].to_s.length >0 )? row["GST (Rs Ps)"] : ''     
               net_amt                  =  (row["Net Amount(Rs.Ps)"].to_s.length >0 )? row["Net Amount(Rs.Ps)"] : ''     
               sub_txn_id               =  (row["Sub Txn Id"].to_s.length >0 )? row["Sub Txn Id"] : ''

                if $checkscaleupdate.to_s == 'Y' ####UPDATE SCALE
                    sewdobj = new_update_employee(biller_id,bank_id,bankrefno,pgirefno,ref1,ref2,ref3,ref4,ref5,ref6,ref7,ref8,date_txn,settle_date,charges,gross_amount,gst,net_amt,sub_txn_id)
                    if sewdobj             
                        $xcount +=1
                    end
                else
              ###### START IMPORT DATA OF EMPLOYEE ########## 
                    # new_fill_allowance_detail($compcodes,empcode,basic,hra,conv,da,otherall,otherall2,mis,bonexgratia)
                   sewdobj = new_update_employee(biller_id,bank_id,bankrefno,pgirefno,ref1,ref2,ref3,ref4,ref5,ref6,ref7,ref8,date_txn,settle_date,charges,gross_amount,gst,net_amt,sub_txn_id)
                   if sewdobj             
                       $xcount +=1
                   end
               end
       end
     end
   
   end
   
   def self.new_update_employee(biller_id,bank_id,bankrefno,pgirefno,ref1,ref2,ref3,ref4,ref5,ref6,ref7,ref8,date_txn,settle_date,charges,gross_amount,gst,net_amt,sub_txn_id)
    compcode      = $compcodes
    mycounst      = 0
    sub_txn_id   = sub_txn_id !=nil && sub_txn_id!='' ? sub_txn_id : ''  
    
    # str = select * from comoponent order by decription
    # do while untill eof
    #   update importtqble set fef4= comoField where ref4=%"Componenet desc"%
    if ref4.present?
      comptobj = MstComponentList.where("compt_compcode = ? AND compt_descp LIKE ?", compcode, "%tuition fee%").first
      if comptobj && ref4.include?("tuition fee")
        ref4_new = comptobj.compt_code
      else
        comptobj = MstComponentList.where("compt_compcode = ? AND compt_descp LIKE ?", compcode, "%institutional fee%").first
        if comptobj && ref4.include?("institutional fee")
          ref4_new = comptobj.compt_code
        else
          comptobj = MstComponentList.where("compt_compcode = ? AND compt_descp LIKE ?", compcode, "%assessment%").first
          if comptobj && ref4.include?("assessment")
            ref4_new = comptobj.compt_code
          else
            comptobj = MstComponentList.where("compt_compcode = ? AND compt_descp LIKE ?", compcode, "%nchm%").first
            if comptobj && ref4.include?("nchm")
              ref4_new = comptobj.compt_code
            else
              comptobj = MstComponentList.where("compt_compcode = ? AND compt_descp LIKE ?", compcode, "%lunch charge%").first
              if comptobj && ref4.include?("lunch charge")
                ref4_new = comptobj.compt_code
              else
                ref4_new = ref4  # Keep the original value if no match is found
              end
            end
          end
        end
      end
    else
      ref4_new = "" # Ensure it's blank if ref4 was blank
    end
    
    
    course = ref8.to_s.strip.downcase
    if course == "diploma in food production"
      xcourse = "9"
    elsif course == "b.sc. hha"
      xcourse = "13"
    elsif course == "db and c"
      xcourse = "10"
    else
      xcourse = ""
    end

  seobjs = TrnFeeImport.where("feeimp_compcode =? AND feeimp_sub_txn_id = ?",compcode,sub_txn_id).first
     if seobjs
          #### Execute if required
          mycounst += 1
     else    
        seobjs  = TrnFeeImport.new(:feeimp_compcode=>compcode,:feeimp_billerid=>biller_id,:feeimp_bankid=>bank_id,:feeimp_bankrefno=>bankrefno,:feeimp_pgirefno=>pgirefno,:feeimp_ref1=>ref1,:feeimp_ref2=>ref2,:feeimp_ref3=>ref3,:feeimp_ref4=>ref4_new,:feeimp_ref5=>ref5,:feeimp_ref6=>ref6,:feeimp_ref7=>ref7,:feeimp_ref8=>xcourse,:feeimp_date_txn=>date_txn,:feeimp_settle_date=>settle_date,:feeimp_gross_amount=>gross_amount,:feeimp_charges=>charges,:feeimp_gst=>gst,:feeimp_net_amt=>net_amt,:feeimp_sub_txn_id=>sub_txn_id)
        seobjs.save
        # fill_student_details(compcode,reg_no,course,category,permanent_address,present_address,city,nationality,hostel,aadhaar_no,contact_no,student_email,bank_account_holder_name,account_no,ifsc_code,course_type)
        # fill_student_family(compcode,reg_no,fam_type,father_name,mother_name,father_mobile,mother_mobile,father_email,mother_email,permanent_address)
        # fill_student_general_detail(compcode,reg_no,nhcm_no,theory_group,practical_group,abc_id,ai_rank,jnu_ignou_no,student_status,semester)
        # fill_personal_2(compcode,empcode,presentaddress,presentphone,presentmobile,premanentaddress,permanentphone,permanentmobile,empcontact,empemail)
        mycounst += 1
     end
     get_fee_process(ref5)
     return mycounst
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
    when ".xls" then Roo::Excel.new(file.path,:packed=> nil, :file_warning=> :ignore)
    when ".xlsx" then Roo::Excelx.new(file.path,:packed=> nil, :file_warning=> :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def self.get_fee_process(ref5)
    compcodes = 'IHM'
    message = ""
    is_flags = false
    fee_data = []

    students = MstStudent.where("stdnt_compcode = ? AND stdnt_reg_no LIKE ?", compcodes,ref5)

    if students.present?
      students.each do |student|
        student_detail = MstStudentDtl.find_by(stdnt_dtl_code: student.stdnt_reg_no)
        student_gen_detail = MstStdntGenDtl.find_by(stdnt_gn_code: student.stdnt_reg_no)

        fee_list = MstFeeList.where(fee_crse: student_detail&.stdnt_dtl_crse, fee_sem: student_gen_detail&.stdnt_gn_cur_sem)

        if fee_list.present?
          fee_list.each do |fee|
            existing_record = TrnFeeProcess.exists?(
              feepr_compcode: compcodes,
              feepr_rollno: student.stdnt_reg_no,
              feepr_course: student_detail&.stdnt_dtl_crse,
              feepr_sem: student_gen_detail&.stdnt_gn_cur_sem,
              feepr_headcomp: fee.fee_compt
            )

            next if existing_record

            fee_record = TrnFeeProcess.create(
              feepr_compcode: compcodes,
              feepr_rollno: student.stdnt_reg_no,
              feepr_name: "#{student.stdnt_fname} #{student.stdnt_lname}",
              feepr_course: student_detail&.stdnt_dtl_crse,
              feepr_sem: student_gen_detail&.stdnt_gn_cur_sem,
              feepr_headcomp: fee.fee_compt,
              feepr_fee: fee.fee_amt,
              feepr_actualfee: '',
              feepr_sub_txn_id: '',
              feepr_txn_date: '',
              feepr_ref_1: '',
              feepr_pgi_ref_no: ''
            )

            fee_import = TrnFeeImport.find_by(
              feeimp_ref5: existing_record.feepr_rollno,
              feeimp_ref8: existing_record.feepr_course,
              feeimp_ref4: existing_record.feepr_headcomp
            )

            if fee_import.present?
              fee_record.update(
                feepr_actualfee: fee_import.feeimp_gross_amount,
                feepr_sub_txn_id: fee_import.feeimp_sub_txn_id,
                feepr_txn_date: fee_import.feeimp_date_txn,
                feepr_ref_1: fee_import.feeimp_ref1,
                feepr_pgi_ref_no: fee_import.feeimp_pgirefno
              )
            end
          end
        end

        fee_data << { student: student, fees: fee_list }
      end
      is_flags = true
      message = "Fee Generated and Updated for the selected year!"
    else
      is_flags = false
      message = "Some error occurred in processing Fee for the selected year!"
    end

  end

end
