module Interakt
  class SendWhatsapp
    INTERAKT_URL = "https://api.interakt.ai/v1/public/message/"

    def self.send_template(phone:, template:, body_values:)
      return { http_code: 0, body: {}, raw: "Invalid phone" } if phone.to_s.length != 10

      uri = URI(INTERAKT_URL)

      payload = {
        countryCode: "+91",
        phoneNumber: phone,
        type: "Template",
        template: {
          name: template,
          languageCode: "en",
          bodyValues: body_values
        }
      }

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Basic #{ENV['INTERAKT_API_KEY']}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = http.request(request)

      {
        http_code: response.code.to_i,
        body: JSON.parse(response.body) rescue {},
        raw: response.body
      }
    end
  end
end
