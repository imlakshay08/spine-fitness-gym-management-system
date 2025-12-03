class FeeProcessController < ApplicationController
    before_action :require_login
    skip_before_action :verify_authenticity_token
    helper_method :currency_formatted,:year_month_days_formatted,:formatted_date

    def index
        @compcodes      = session[:loggedUserCompCode] 
        if params[:id].to_i>0
            @fee_process=TrnFeeProcess.where("feepr_compcode=? AND id=?",@compcodes,params[:id]).first
        end  
        @fee_processes=TrnFeeProcess.where("feepr_compcode=? ",@compcodes)
    end

    def ajax_process
        @compcodes      = session[:loggedUserCompCode] 
        if params[:identity] != nil && params[:identity] != '' && params[:identity] == "FEEPROCESS"
            get_fee_process()
            return
        end
    end
    
    def get_fee_process
        @compcodes = session[:loggedUserCompCode] 
        year = params[:feepr_year].to_i
        rollno = year % 100
        message = ""
        isFlags = false
        fee_data = []  # Initialize an empty array
      
        students = MstStudent.where("stdnt_compcode = ? AND stdnt_reg_no LIKE ?", @compcodes, "#{rollno}%")
      
        if students.present?
          students.each do |student|
            student_detail = MstStudentDtl.find_by(stdnt_dtl_code: student.stdnt_reg_no)
            student_gen_detail = MstStdntGenDtl.find_by(stdnt_gn_code: student.stdnt_reg_no)
      
            fee_list = MstFeeList.where(fee_year: year, fee_crse: student_detail.stdnt_dtl_crse, fee_sem: student_gen_detail.stdnt_gn_cur_sem)
      
            if fee_list.present?
              fee_list.each do |fee|
                # Check if the fee record already exists
                existing_record = TrnFeeProcess.exists?(
                  feepr_compcode: @compcodes,
                  feepr_rollno: student.stdnt_reg_no,
                  feepr_course: student_detail.stdnt_dtl_crse,
                  feepr_sem: student_gen_detail.stdnt_gn_cur_sem,
                  feepr_headcomp: fee.fee_compt
                )
      
                next if existing_record # Skip insertion if record exists
      
                # Insert new record
                fee_record = TrnFeeProcess.create(
                  feepr_compcode: @compcodes,
                  feepr_rollno: student.stdnt_reg_no,
                  feepr_name: "#{student.stdnt_fname} #{student.stdnt_lname}",
                  feepr_course: student_detail.stdnt_dtl_crse,
                  feepr_sem: student_gen_detail.stdnt_gn_cur_sem,
                  feepr_headcomp: fee.fee_compt,
                  feepr_fee: fee.fee_amt,
                  feepr_actualfee: '',
                  feepr_sub_txn_id: '',
                  feepr_txn_date: '',
                  feepr_ref_1: '',
                  feepr_pgi_ref_no: ''
                )
      
                # Fetch corresponding fee import data
                fee_import = TrnFeeImport.find_by(
                  feeimp_ref5: fee_record.feepr_rollno,
                  feeimp_ref8: fee_record.feepr_course,
                  feeimp_ref4: fee_record.feepr_headcomp
                )
      
                # Update fee process record with imported data
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
          isFlags = true
          message = "Fee Generated and Updated for the selected year!"
        else
          isFlags = false
          message = "Some error occurred in processing Fee for the selected year!"
        end
      
        respond_to do |format|
          format.json { render json: { 'year' => year, 'message' => message, data: fee_data, status: isFlags } }
        end
      end
      
end
