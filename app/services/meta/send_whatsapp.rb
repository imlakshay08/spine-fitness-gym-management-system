module Meta
  class SendWhatsapp
    API_URL = "https://graph.facebook.com/v19.0"

    def self.send_template(phone:, template:, body_values:)
      phone = phone.to_s.gsub(/\D/, "").last(10)
      return { http_code: 0, body: {}, raw: "Invalid phone" } unless phone.length == 10

      uri = URI("#{API_URL}/#{ENV['WHATSAPP_PHONE_ID']}/messages")

      payload = {
        messaging_product: "whatsapp",
        to: "91#{phone}",
        type: "template",
        template: {
          name: template,
          language: { code: "en" },
          components: [{
            type: "body",
            parameters: body_values.map { |v| { type: "text", text: v.to_s } }
          }]
        }
      }

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{ENV['WHATSAPP_TOKEN']}"
      request["Content-Type"]  = "application/json"
      request.body = payload.to_json

      response = http.request(request)
      parsed_body = JSON.parse(response.body) rescue {}

      { http_code: response.code.to_i, body: parsed_body, raw: response.body }
    end
  end
end