module Meta
  class SendWhatsapp
    API_URL = "https://graph.facebook.com/v19.0"

    # `document:` attaches a PDF to the template's header component, e.g.
    #   { id: "<media id from upload_media>", filename: "Receipt-PAY001.pdf" }
    # The template must have been approved WITH a document header for this to
    # be accepted — a text-only template rejects the header component.
    def self.send_template(phone:, template:, body_values:, document: nil)
      phone = phone.to_s.gsub(/\D/, "").last(10)
      return { http_code: 0, body: {}, raw: "Invalid phone" } unless phone.length == 10

      uri = URI("#{API_URL}/#{ENV['WHATSAPP_PHONE_ID']}/messages")

      components = []
      if document.present?
        components << {
          type: "header",
          parameters: [{
            type: "document",
            document: { id: document[:id].to_s, filename: document[:filename].to_s }
          }]
        }
      end
      components << {
        type: "body",
        parameters: body_values.map { |v| { type: "text", text: v.to_s } }
      }

      payload = {
        messaging_product: "whatsapp",
        to: "91#{phone}",
        type: "template",
        template: {
          name: template,
          language: { code: "en" },
          components: components
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

    # Uploads a file to the WhatsApp media store and returns its media id.
    # The id is what a template header references; it stays valid long enough
    # to send with (Meta retains uploaded media for ~30 days).
    def self.upload_media(file_path:, mime_type: "application/pdf")
      unless File.exist?(file_path)
        return { http_code: 0, body: {}, raw: "File not found: #{file_path}" }
      end

      url  = "#{API_URL}/#{ENV['WHATSAPP_PHONE_ID']}/media"
      file = File.new(file_path, "rb")

      response = RestClient.post(
        url,
        { messaging_product: "whatsapp", type: mime_type, file: file },
        { Authorization: "Bearer #{ENV['WHATSAPP_TOKEN']}" }
      )

      { http_code: response.code.to_i,
        body:      (JSON.parse(response.body) rescue {}),
        raw:       response.body.to_s }
    rescue RestClient::ExceptionWithResponse => e
      { http_code: e.response&.code.to_i || 0,
        body:      (JSON.parse(e.response.to_s) rescue {}),
        raw:       e.response.to_s }
    rescue StandardError => e
      { http_code: 0, body: {}, raw: "#{e.class}: #{e.message}" }
    ensure
      file.close if defined?(file) && file.respond_to?(:close) && !file.closed?
    end

    def self.send_text(phone:, message:)
      phone = phone.to_s.gsub(/\D/, "").last(10)
      return { http_code: 0, body: {}, raw: "Invalid phone" } unless phone.length == 10

      uri = URI("#{API_URL}/#{ENV['WHATSAPP_PHONE_ID']}/messages")

      payload = {
        messaging_product: "whatsapp",
        to: "91#{phone}",
        type: "text",
        text: { body: message }
      }

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{ENV['WHATSAPP_TOKEN']}"
      request["Content-Type"] = "application/json"
      request.body = payload.to_json

      response = http.request(request)
      parsed_body = JSON.parse(response.body) rescue {}
      { http_code: response.code.to_i, body: parsed_body, raw: response.body }
    end
  end
end