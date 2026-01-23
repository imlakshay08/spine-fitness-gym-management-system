require 'net/http'
require 'json'

module Interakt
  class SendWhatsapp
    INTERAKT_URL = "https://api.interakt.ai/v1/public/message/"

    def self.send_membership_expiry(phone:, name:, expiry_date)
      return if phone.to_s.length != 10   # hard safety

      uri = URI(INTERAKT_URL)

      payload = {
        countryCode: "+91",
        phoneNumber: phone,                # 10-digit only
        type: "Template",
        template: {
          name: "membership_expiry_reminder",
          languageCode: "en",
          bodyValues: [
            name,
            expiry_date.strftime("%d %b %Y")
          ]
        }
      }

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Basic #{ENV['INTERAKT_API_KEY']}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = http.request(request)

      Rails.logger.info("[INTERAKT] #{phone} → #{response.code}")
      response
    end
  end
end
