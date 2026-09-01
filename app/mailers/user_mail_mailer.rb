class UserMailMailer < ApplicationMailer
   before_action :apps_detail_list
  def generatelogin_confrimation(password,usersname,email,bodys)
    @password  = password
    @usersname = usersname
    
   isitem = bodys
    mail(:to =>email,
         :subject => "Your Login Credential - inqpos.com",
         :body=>isitem,
         :content_type=> "text/html"         
         )

end
def _send_otp_on_mail_(email, subject, message, attachment_path = nil, attachment_name = nil)
  @message = message

  mail(to: email, subject: subject) do |format|
    format.html { render html: @message.html_safe }

    # Handle optional attachment
    if attachment_path.present? && attachment_name.present?
      attachments[attachment_name] = File.read(attachment_path)
    end
  end
end 
def _send_mail_attachment_(email,subject,bodys,printnames,pdfa,arg={})
     ###SET COMPANY WISE EMAIL:: IF BLANK THEN IT WILL SEND FROM DEFAULT SETTING####
     myfrommailed = nil
     if arg.length >0
          if( arg[:host].to_s.present? && arg[:port].to_s.present? && arg[:username].to_s.present? && arg[:password].to_s.present? )  
              myfrommailed = arg[:from]
             set_runtime_smtp_configuration(arg[:host],arg[:port],arg[:username],arg[:password]) 
          end
     
    end
  
  isdate   = Time.now.to_date    
  if pdfa!=nil && pdfa!=''
    printname = printnames.to_s
    attachments[printname.to_s+".pdf"] = {:mime_type => "application/pdf" , :content => pdfa }
  end
  if( myfrommailed && myfrommailed.to_s.present? )
      mixed = mail(:to =>email,
         :subject =>subject,
         :body=>bodys,
         :content_type=> "text/html" ,
         :from=>myfrommailed
      )
  else
      
     mixed = mail(:to =>email,
         :subject =>subject,
         :body=>bodys,
         :content_type=> "text/html"
         
      )  
      
  end
  
   if pdfa!=nil && pdfa!=''
      mixed.content_type 'multipart/mixed'
      mixed.header['content-type'].parameters[:boundary] = mixed.body.boundary
      mixed.content_disposition = nil
   end
end

private
def set_runtime_smtp_configuration(host,port,username,password)
        smtp_settings = {
          address: host,
          port: port,
          user_name: username,
          password: password,
          authentication: 'plain',
          enable_starttls_auto: true
        }
      ActionMailer::Base.smtp_settings = smtp_settings
  end


end
