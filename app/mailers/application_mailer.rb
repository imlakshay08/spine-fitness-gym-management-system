class ApplicationMailer < ActionMailer::Base
 default :from=> 'info@inquisitor.in'
   layout 'mailer'
  private
  # Inherited SMS-gateway settings. The gym product sends no SMS and no email
  # at all — WhatsApp via Meta Cloud API is the only outbound channel — so the
  # real gateway key, sender id and campaign id were removed from source and
  # are read from the environment if this is ever wired up again.
  def apps_detail_list
      @api_key   = ENV['SMS_GATEWAY_API_KEY'].to_s
      @senders   = ENV['SMS_GATEWAY_SENDER_ID'].to_s
      @routeid   = ENV['SMS_GATEWAY_ROUTE_ID'].to_s
      @campaign  = ENV['SMS_GATEWAY_CAMPAIGN_ID'].to_s
      @senPath   = ENV['SMS_GATEWAY_URL'].to_s
      @LinkCop   = ENV['SMS_GATEWAY_LINK'].to_s
  end
end
