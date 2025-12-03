class ApplicationMailer < ActionMailer::Base
 default :from=> 'info@inquisitor.in'
   layout 'mailer'
  private
  def apps_detail_list
      @api_key   = '46017979D9B5EB';
      @senders   = 'INQUIS' #WDGDRS
      @routeid   = "7"
      @campaign  = "10728"
      @senPath   = "http://kutility.in/app/smsapi/index.php"
      @LinkCop   = "http://kidilios.com"

  end
end


