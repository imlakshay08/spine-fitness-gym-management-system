require 'faraday'
require 'uri'
require 'erb'
class StudentInfoController < ApplicationController

    # before_action :require_login
    before_action :get_user_access_permissions
    skip_before_action :verify_authenticity_token,:only=>[:index,:ajax_process]
    def index
        @compcodes        = "IHM"
        global_email_configs_mail()
        if params[:id].to_i>0
            @studentadm = MstStudent.where("stdnt_compcode=? AND id=?",@compcodes,params[:id]).first
        end
        #  UserMailMailer._send_mail_attachment_("singh4460@gmail.com","sss","test",'','').deliver
    end

    def ajax_process
      @compcodes = "IHM"
      if params[:identity] != nil && params[:identity] != '' && params[:identity] == 'STDNT'
        upload_student_img_sign();
        return
      elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'EMAIL'
        send_otp_on_email();
        return
        
      elsif params[:identity] != nil && params[:identity] != '' && params[:identity] == 'VRFOTP'
        verify_otp_on_email();
        return
        
      end
    end

    def create
    #   @compcodes = "IHM"
    #   isFlags = true
    #   mid = params[:mid]
    
    #   profileid = ""
    
    #   begin
    #     if params[:stdnt_reg_no].present?
    #       # Check if the student with this registration number already exists
    #       existing_student = MstStudent.where("stdnt_compcode = ? AND stdnt_reg_no = ?", @compcodes, params[:stdnt_reg_no]).first
          
    #       if existing_student
    #         # Updating existing student details
    #             isSFlag    = true
    #             isSGFlg    = true
    #                   @studimg    = existing_student.stdnt_img
    #                   @studsign   = existing_student.stdnt_signature
    #                   if @studimg.to_s.present?
    #                         isSFlag = false 
    #                   end
    #                   if @studsign.to_s.present?
    #                         isSGFlg = false 
    #                   end
    #                  if isSFlag && isSGFlg
    #                         profileid = existing_student.id
    #                         if existing_student.update(student_params)
    #                           message = "Data updated successfully"
    #                         else
    #                           message = "Failed to update data"
    #                           isFlags = false
    #                         end
    #                  else
    #                           message = "The student's profile picture and signature have been successfully updated."
    #                           isFlags = false  
    #                 end
    #           else
    #         # Insert new student record
    #             new_student = MstStudent.new(student_params)
    #             if new_student.save
    #               profileid = new_student.id
    #               message = "Data saved successfully"
    #             else
    #               message = "Failed to save data"
    #               isFlags = false
    #             end
    #       end
    #     else
    #       message = "Registration number is missing"
    #       isFlags = false
    #     end
    #   rescue Exception => exc
    #     message = "ERROR: #{exc.message}"
    #     isFlags = false
    #   end
    # #   if isFlags
    # #     redirect_to  "#{root_url}student_info"
    # # else
    # #     if params[:mid].to_i>0 
    # #         redirect_to  "#{root_url}student_info"
    # #     else
    # #         redirect_to  "#{root_url}student_info"
    # #     end
          
    # # end
    end
   def verify_otp_on_email
    @compcodes = "IHM"
    status     = true
    message    = ""  
    # Ensure `reg_no` is provided by the user
    otp      = params[:otp].to_s.present? ? set_dct(params[:otp].to_s.strip) : ''
    registno = params[:registno].to_s.present? ? set_dct(params[:registno].to_s.strip) : ''

  begin
      if registno.blank?
        message = "Registration number is required."
        status     = false
      end
      if otp.blank?
        message = "OTP is required."
        status     = false
      end
      if status
      # Ensure @compcodes is not nil and proceed with the student lookup
          student = MstStudentDtl.find_by(stdnt_dtl_compcode: @compcodes, stdnt_dtl_code: registno,stdnt_otp:otp)        
          if student && student.length >0
            status = true
          else
              status = false
              message = "Invalid OTP."
          end
      
    end
    rescue Exception => exc   
        message = "UNKON ERROR: #{exc.message}" ##{exc.message}
        isFlags = false
    end
  
       # Respond with JSON
        respond_to do |format|
          format.json { render json: { status: status, message: message } }
        end
   end

    
    def send_otp_on_email
      @compcodes = "IHM"
      status = false
      message = ""
       otp    = generate_common_numbers(6)
      # Ensure `reg_no` is provided by the user
      reg_no = params[:stdnt_reg_no].to_s.strip
    begin
      if reg_no.blank?
        message = "Registration number is required."
      else
        # Ensure @compcodes is not nil and proceed with the student lookup
          student = MstStudentDtl.find_by(stdnt_dtl_compcode: @compcodes, stdnt_dtl_code: reg_no)
          
          if student.present?
                email   = student.stdnt_dtl_email
                rollnum = student.stdnt_dtl_code
                if email.present?
                 process_send_link_to_user_email(email,rollnum,otp)
                  status  = true
                  message = "OTP sent to your email."
                  student.update(:stdnt_otp=>otp)
                  
                else
                  message = "No email found for this student."
                end
          else
              message = "No student found with this registration number."
          end
        
      end
       rescue Exception => exc
     
        message = "ERROR: #{exc.message}"
        isFlags = false
      end
    
      # Respond with JSON
      respond_to do |format|
        format.json { render json: { data: '', status: status, message: message } }
      end
    end
    
    
    

    def process_send_link_to_user_email(email, rollnum,otp)
      subject = "OTP"
      global_email_configs_mail()
      # Check if email is present to avoid unnecessary operations
      if email.present?
        # Use `render_to_string` to generate the email body from the template
        message = render_to_string(template: 'student_info/otp_on_email', layout: false, locals: { email: email, rollnum: rollnum,otp:otp })
       # Send the email using the mailer method
        UserMailMailer._send_mail_attachment_(email,subject,message,'','',@globalEmail).deliver
      else
        Rails.logger.debug("Email not present for roll number: #{rollnum}")
      end
    end
    

    private
    def upload_student_img_sign
      @compcodes   = "IHM"
      isFlags      = true
      mid          = params[:mid]
      profileid    = ""
      profileimage = ""
     signimages   = ""
      message      = ""
 
     begin
      if params[:stdnt_reg_no].present?
       # Check if the student with this registration number already exists
        existing_student = MstStudent.where("stdnt_reg_no = ?", params[:stdnt_reg_no]).first
       
       if existing_student
         # Updating existing student details
         profileid = existing_student.id
         profileimage = existing_student.stdnt_img
         signimages = existing_student.stdnt_signature
         isSFlag    = true
         isSGFlg    = true
         @studimg    = existing_student.stdnt_img
         @studsign   = existing_student.stdnt_signature
         
         # Commented out the flags checking logic
        #  if @studimg.to_s.present?
        #    isSFlag = false 
        #  end
         
        #  if @studsign.to_s.present?
         #   isSGFlg = false 
        #  end
         
         # Commented out the condition that prevents re-uploading
        #  if isSFlag && isSGFlg
           if existing_student.update(student_params)
             message = "Data updated successfully"
           else
             message = "Failed to update data"
             isFlags = false
           end
        #  else
         #   message = "The student's profile picture and signature have already been captured."
        #    isFlags = false  
        #  end
         
       else
         message = "The registration number is invalid."
         isFlags = false
       end
     else
       message = "The registration number is invalid."
       isFlags = false
     end
   rescue Exception => exc
     message = "ERROR: #{exc.message}"
     isFlags = false
   end
 
   respond_to do |format|
     format.json { render json: { message: message, profileid: profileid, profileimage: profileimage, signimages: signimages, status: isFlags } }
   end
 end
 
    private
    def student_params
      params[:stdnt_compcode] = "IHM"
      compcodes                =  "IHM"
      imgfolder  = "student"
      signs      = "studentsign"
      attachfile = ""
      signattach = ""
      currcategoryimage = @studimg
      cursignature      = @studsign
      if params[:studentattach_file].present?   
        
            if params[:mid].to_i > 0
                  if currcategoryimage.to_s.present?
                      storage_path = "#{compcodes}/student"
                      bunny_delete_storage_file(currcategoryimage,storage_path)  
                     
                  end
          end          
          attachfile = process_files_pos(params[:studentattach_file], params[:currcategoryimage], imgfolder)
            
      end
      if attachfile.to_s.blank?
          if currcategoryimage.to_s.present?
              attachfile = currcategoryimage
          end      
      end   
      if params[:stdnt_signature].present?        
          if params[:mid].to_i > 0          
                if cursignature.to_s.present?
                    signs_path = "#{compcodes}/studentsign"
                    bunny_delete_storage_file(cursignature,signs_path)                  
                end
          end         
       signattach = process_without_base64_files(params[:stdnt_signature], params[:cursignature], signs)   
    
    end
    if signattach.to_s.blank?
        if cursignature.to_s.present?
          signattach = cursignature
        end      
    end  
      params[:stdnt_signature] = signattach
      params[:stdnt_img]       = attachfile 
      params.permit(:stdnt_compcode,:stdnt_signature,:stdnt_reg_no,:stdnt_img)

    end

  
end
