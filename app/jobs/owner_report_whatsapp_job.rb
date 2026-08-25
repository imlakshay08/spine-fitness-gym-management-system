require 'tempfile'

# Sends the owner her daily or monthly gym report as a WhatsApp message with
# the full PDF attached.
#
# Business-initiated like the receipt, so it goes out as an approved template
# with a document header — the owner has no open 24-hour window.
#
# Recipients come from OWNER_WHATSAPP_NUMBERS (comma separated) so a second
# number can be added without a deploy.
class OwnerReportWhatsappJob < ApplicationJob
  queue_as :default

  TEMPLATE       = 'gym_owner_report'.freeze
  DEFAULT_NUMBER = '9871946454'.freeze   # Poonam Tyagi
  DEFAULT_NAME   = 'Poonam'.freeze

  # Returns a one-line summary so the cron endpoint can hand it straight back
  # to whatever pinged it — a silent failure is what made this invisible once.
  def perform(kind = :daily, compcode = 'SF', on = nil)
    kind = kind.to_sym
    log("starting #{kind} report (compcode=#{compcode}, on=#{on || 'default'})")

    data = build_report(kind, compcode, on)
    return log_and_return('no report data could be built') if data.blank?

    company  = MstCompany.find_by(cmp_companycode: compcode)
    renderer = Reports::GymReportPdf.new(data: data, company: company)
    media_id = upload(renderer)

    sent = recipients.map { |number, name| send_to(number, name, kind, data, renderer, media_id, compcode) }

    pdf_note = media_id.present? ? 'with PDF' : 'WITHOUT PDF (upload failed)'
    summary  = "#{kind} report for #{data[:period]}: #{sent.count(true)}/#{sent.size} sent #{pdf_note}"
    log(summary)
    summary
  ensure
    cleanup(@tempfile)
  end

  private

  def build_report(kind, compcode, on)
    case kind
    when :daily
      Reports::DailyGymReport.new(date: on, compcode: compcode).call
    when :monthly
      Reports::MonthlyGymReport.new(month: on, compcode: compcode).call
    end
  rescue StandardError => e
    Rails.logger.error "[OwnerReport] could not build #{kind} report: #{e.class}: #{e.message}"
    nil
  end

  def recipients
    raw = ENV['OWNER_WHATSAPP_NUMBERS'].to_s.strip
    list = raw.present? ? raw.split(',').map(&:strip).reject(&:blank?) : [DEFAULT_NUMBER]
    list.map { |number| [number, number == DEFAULT_NUMBER ? DEFAULT_NAME : 'there'] }
  end

  def upload(renderer)
    @tempfile = Tempfile.new(['gym-report', '.pdf'])
    @tempfile.binmode
    @tempfile.write(renderer.render)
    @tempfile.flush
    @tempfile.close

    result = Meta::SendWhatsapp.upload_media(file_path: @tempfile.path, mime_type: 'application/pdf')
    result.dig(:body, 'id')
  rescue StandardError => e
    Rails.logger.error "[OwnerReport] PDF build/upload failed: #{e.class}: #{e.message}"
    nil
  end

  def send_to(number, name, kind, data, renderer, media_id, compcode)
    values   = body_values(name, kind, data)
    response = Meta::SendWhatsapp.send_template(
      phone:       number,
      template:    TEMPLATE,
      body_values: values,
      document:    media_id.present? ? { id: media_id, filename: renderer.filename } : nil
    )

    success = response[:http_code].to_i.between?(200, 299) &&
              response.dig(:body, 'messages', 0, 'id').present?

    TrnWhatsappLog.create!(
      wl_compcode:        compcode,
      wl_member_id:       nil,                     # the owner is not a member
      wl_subscription_id: nil,
      wl_template_name:   TEMPLATE,
      wl_message_body:    WhatsappTemplates.render(TEMPLATE, *values),
      wl_sent_at:         Time.current,
      wl_status:          success ? 'QUEUED' : 'FAILED',
      wl_interakt_msg_id: response.dig(:body, 'messages', 0, 'id'),
      wl_api_response:    response[:raw],
      wl_failed_reason:   success ? nil : (response.dig(:body, 'error', 'message').presence || "HTTP #{response[:http_code]}")
    )

    log("#{kind} report to #{number} pdf=#{media_id.present? ? 'attached' : 'MISSING'} sent=#{success}")
    success
  end

  # Must match {{1}}..{{8}} in the approved template.
  def body_values(name, kind, data)
    if kind == :daily
      [
        name,
        'daily',
        data[:period],
        strip_rs(data[:money][:total_text]),
        data[:sales].size.to_s,
        data[:footfall][:unique].to_s,
        data[:turned_away].size.to_s,
        daily_attention(data)
      ]
    else
      [
        name,
        'monthly',
        data[:period],
        strip_rs(data[:money][:total_text]),
        (data[:growth][:new_members] + data[:growth][:renewals]).to_s,
        data[:footfall][:visits].to_s,
        data[:footfall][:denied_members].to_s,
        monthly_attention(data)
      ]
    end
  end

  def daily_attention(data)
    bits = []
    bits << "#{data[:attention][:expiring_7].size} expiring in 7 days" if data[:attention][:expiring_7].any?
    bits << "#{data[:attention][:lapsed_45].size} lapsed"              if data[:attention][:lapsed_45].any?
    bits << "#{data[:attention][:quiet_14].size} not turning up"       if data[:attention][:quiet_14].any?
    bits.any? ? bits.join(', ') : 'nothing urgent'
  end

  def monthly_attention(data)
    bits = []
    bits << "#{data[:growth][:lost]} not renewed"                        if data[:growth][:lost].to_i.positive?
    bits << "#{data[:outlook][:expiring_count]} expiring next month"     if data[:outlook][:expiring_count].to_i.positive?
    bits.any? ? bits.join(', ') : 'nothing urgent'
  end

  # The template already prints "Rs." before the variable.
  def strip_rs(text)
    text.to_s.sub(/\ARs\.\s*/, '')
  end

  def cleanup(tempfile)
    return if tempfile.nil?
    tempfile.close unless tempfile.closed?
    tempfile.unlink
  rescue StandardError
    nil
  end

  def log(message)
    Rails.logger.info "[OwnerReport] #{message}"
    message
  end

  def log_and_return(message)
    log(message)
    message
  end
end
