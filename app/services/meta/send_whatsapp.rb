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

    # Incoming media is never sent as a file: the webhook gives a media id, that
    # id is exchanged for a short-lived signed URL, and the URL itself only
    # serves bytes when called with the access token. Both hops happen here.
    #
    # Meta keeps uploaded media for about 30 days, after which the id stops
    # resolving — old attachments will report as unavailable.
    def self.download_media(media_id)
      return nil if media_id.blank?

      lookup = Net::HTTP.get_response(
        URI("#{API_URL}/#{media_id}"),
        'Authorization' => "Bearer #{ENV['WHATSAPP_TOKEN']}"
      )
      return nil unless lookup.is_a?(Net::HTTPSuccess)

      meta = JSON.parse(lookup.body) rescue {}
      url  = meta['url']
      return nil if url.blank?

      uri  = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{ENV['WHATSAPP_TOKEN']}"
      response = http.request(request)
      return nil unless response.is_a?(Net::HTTPSuccess)

      { data: response.body,
        mime: meta['mime_type'].presence || response['content-type'].presence || 'application/octet-stream',
        size: meta['file_size'] }
    rescue StandardError => e
      Rails.logger.error "[Meta] media #{media_id} download failed: #{e.class}: #{e.message}"
      nil
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