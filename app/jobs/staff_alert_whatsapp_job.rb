require 'tempfile'

# Messages for the floor staff — never for the owner, and never containing
# money. Two kinds:
#
#   :biometric  urgent, text only, sent while the gym is open when the
#               fingerprint bridge stops reporting in
#   :weekly     the Monday list, with the full names-and-numbers PDF attached
#
# Recipients come from mst_staff_lists by id (STAFF_ALERT_IDS, default "4,2" —
# Vishal and Mani), so changing a phone number in Staff List is enough; nothing
# is hardcoded. STAFF_ALERT_EXTRA adds anyone not in that table.
class StaffAlertWhatsappJob < ApplicationJob
  queue_as :default

  ALERT_TEMPLATE  = 'alert_for_staff'.freeze
  WEEKLY_TEMPLATE = 'staff_weekly_list'.freeze

  DEFAULT_STAFF_IDS = '4,2'.freeze            # Vishal Tyagi, Vineet (Mani)

  # People who get staff alerts but are not rows in mst_staff_lists. Poonam is
  # here because an outage costs her money and she asked to see it — this is
  # the floor alert only. Her owner report stays separate and stays private to
  # her and Lakshay; nothing about it is shared with the staff recipients.
  DEFAULT_EXTRA = '9871946454:Lakshay,9990899992:Poonam'.freeze

  # An outage that lasts all morning should not send a message every 15 minutes.
  REPEAT_AFTER = 2.hours

  def perform(kind = :biometric, compcode = 'SF')
    case kind.to_sym
    when :biometric then run_biometric(compcode)
    when :weekly    then run_weekly(compcode)
    else "unknown alert kind #{kind}"
    end
  ensure
    cleanup(@tempfile)
  end

  private

  # ── biometric outage ──────────────────────────────────────────────────────

  def run_biometric(compcode)
    alert = Alerts::BiometricWatch.new(compcode: compcode).call
    return log('gym closed or bridge is alive — nothing to send') if alert.nil?

    if sent_recently?(compcode, ALERT_TEMPLATE, alert[:kind])
      return log('bridge still down, but staff were told within the last 2 hours')
    end

    sent = recipients.map do |number, name|
      deliver(compcode, ALERT_TEMPLATE, alert[:kind], number,
              [name, alert[:service], alert[:status], alert[:action]])
    end

    summary = "biometric alert: #{sent.count(true)}/#{sent.size} sent"
    log(summary)
    summary
  end

  # ── Monday list ───────────────────────────────────────────────────────────

  def run_weekly(compcode)
    data     = Alerts::StaffDigest.new(compcode: compcode).call
    company  = MstCompany.find_by(cmp_companycode: compcode)
    renderer = Reports::StaffFollowupPdf.new(data: data, company: company)
    media_id = upload(renderer)

    to_fix = data[:not_recorded].size + data[:not_enrolled].size

    sent = recipients.map do |number, name|
      deliver(compcode, WEEKLY_TEMPLATE, 'WEEK', number,
              [name, data[:period], plural(data[:absent].size),
               plural(to_fix), plural(data[:bad_numbers].size)],
              media_id, renderer.filename)
    end

    summary = "weekly staff list: #{sent.count(true)}/#{sent.size} sent" \
              "#{media_id.present? ? ' with PDF' : ' WITHOUT PDF (upload failed)'}"
    log(summary)
    summary
  end

  def plural(count)
    "#{count} member#{'s' if count != 1}"
  end

  # ── recipients ────────────────────────────────────────────────────────────

  def recipients
    @recipients ||= begin
      ids  = ENV.fetch('STAFF_ALERT_IDS', DEFAULT_STAFF_IDS).split(',').map(&:strip).reject(&:blank?)
      list = MstStaffList.where(id: ids).map do |staff|
        number = staff.stf_contact.to_s.gsub(/\D/, '')
        next if number.length < 10

        [number, staff.stf_name.to_s.split.first.presence || 'there']
      end.compact

      ENV.fetch('STAFF_ALERT_EXTRA', DEFAULT_EXTRA).split(',').each do |entry|
        number, name = entry.to_s.split(':', 2).map { |part| part.to_s.strip }
        next if number.blank?

        list << [number, name.presence || 'there']
      end

      list.uniq { |number, _| number }
    end
  end

  # ── sending ───────────────────────────────────────────────────────────────

  def deliver(compcode, template, kind_code, number, values, media_id = nil, filename = nil)
    response = Meta::SendWhatsapp.send_template(
      phone:       number,
      template:    template,
      body_values: values,
      document:    media_id.present? ? { id: media_id, filename: filename } : nil
    )

    success = response[:http_code].to_i.between?(200, 299) &&
              response.dig(:body, 'messages', 0, 'id').present?

    TrnWhatsappLog.create!(
      wl_compcode:        compcode,
      wl_member_id:       nil,          # staff, not a member
      wl_subscription_id: kind_code,    # short code so repeats can be throttled
      wl_template_name:   template,
      wl_message_body:    WhatsappTemplates.render(template, *values),
      wl_sent_at:         Time.current,
      wl_status:          success ? 'QUEUED' : 'FAILED',
      wl_interakt_msg_id: response.dig(:body, 'messages', 0, 'id'),
      wl_api_response:    response[:raw],
      wl_failed_reason:   success ? nil : (response.dig(:body, 'error', 'message').presence || "HTTP #{response[:http_code]}")
    )

    log("#{template} to #{number} sent=#{success}")
    success
  end

  def sent_recently?(compcode, template, kind_code)
    TrnWhatsappLog
      .where(wl_compcode: compcode, wl_template_name: template, wl_subscription_id: kind_code)
      .where.not(wl_status: 'FAILED')
      .where('wl_sent_at >= ?', REPEAT_AFTER.ago)
      .exists?
  end

  def upload(renderer)
    @tempfile = Tempfile.new(['staff-list', '.pdf'])
    @tempfile.binmode
    @tempfile.write(renderer.render)
    @tempfile.flush
    @tempfile.close

    Meta::SendWhatsapp.upload_media(file_path: @tempfile.path, mime_type: 'application/pdf')
                      &.dig(:body, 'id')
  rescue StandardError => e
    Rails.logger.error "[StaffAlert] PDF build/upload failed: #{e.class}: #{e.message}"
    nil
  end

  def cleanup(tempfile)
    return if tempfile.nil?
    tempfile.close unless tempfile.closed?
    tempfile.unlink
  rescue StandardError
    nil
  end

  def log(message)
    Rails.logger.info "[StaffAlert] #{message}"
    message
  end
end
