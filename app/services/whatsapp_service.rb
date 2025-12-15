require 'net/http'
require 'uri'

class WhatsappService
  def self.send_message(phone, message, api_key)
    message = URI.encode(message)
    url = "https://api.callmebot.com/whatsapp.php?phone=#{phone}&text=#{message}&apikey=#{api_key}"

    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    response.code == "200"
  end
end
