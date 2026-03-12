require 'net/http'
require 'uri'

class WhatsappService
  def self.send_message(phone, message, api_key)
    encoded_message = URI.encode_www_form_component(message)
    url = "https://api.callmebot.com/whatsapp.php?phone=#{phone}&text=#{encoded_message}&apikey=#{api_key}"

    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    response.code == "200"
  end
end
