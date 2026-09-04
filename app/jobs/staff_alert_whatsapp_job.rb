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

  ALERT_TEMPLATE   = 'alert_for_staff'.freeze
  WEEKLY_TEMPLATE  = 'staff_weekly_list'.freeze
  MORNING_TEMPLATE = 'staff_morning_list'.freeze

  DEFAULT_STAFF_IDS = '4,2'.freeze            # Vishal Tyagi, Vineet (Mani)

  # People who get staff alerts but are not rows in mst_staff_lists, as
  # "number:Name:role". The role picks which set of instructions the biometric
  # alert carries: :staff are at the gym and are told to fix it, :owner is not
  # and is told who to call. Anything without a role is treated as :staff.
  #
  # Lakshay is listed twice on purpose — he gets the staff wording and the
  # owner wording for the same outage, so he can see exactly what each of them
  # was told. Poonam is here because an outage costs her money and she asked to
  # see it; this is the floor alert only, and her owner report stays separate
  # and stays private to her and Lakshay.
  DEFAULT_EXTRA = '9871946454:Lakshay:staff,9871946454:Lakshay:owner,9990899992:Poonam:owner'.freeze

  # An outage that lasts all morning should not send a message every 15 minutes.
  REPEAT_AFTER = 2.hours

  def perform(kind = :biometric, compcode = 'SF')
    case kind.to_sym
    when :biometric then run_biometric(compcode)
    when :weekly    then run_weekly(compcode)
    when :morning   then run_morning(compcode)
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

    names = gym_staff_names

    sent = recipients.map do |number, name, role|
      steps  = alert[:action][role] || alert[:action][:staff]
      action = steps.gsub('%{staff}') { names }

      deliver(compcode, ALERT_TEMPLATE, alert[:kind], number,
              [name, alert[:service], alert[:status], action])
    end

    summary = "biometric alert: #{sent.count(true)}/#{sent.size} sent"
    log(summary)
    summary
  end

  # Who to name in the owner's "call them at the gym" line. Read from the Staff
  # List in the order STAFF_ALERT_IDS lists them, so the manager comes first,
  # and keeping any nickname in brackets — Poonam knows Vineet as Mani.
  def gym_staff_names
    rows  = MstStaffList.where(id: staff_ids).index_by { |s| s.id.to_s }
    names = staff_ids.filter_map { |id| short_name(rows[id]&.stf_name) }

    return 'the trainers' if names.empty?
    return names.first    if names.size == 1

    "#{names[0..-2].join(', ')} and #{names.last}"
  end

  def short_name(full)
    base = full.to_s.split.first
    return nil if base.blank?

    nickname = full.to_s[/\([^)]*\)/]
    nickname ? "#{base} #{nickname}" : base
  end

  def staff_ids
    @staff_ids ||= ENV.fetch('STAFF_ALERT_IDS', DEFAULT_STAFF_IDS)
                      .split(',').map(&:strip).reject(&:blank?)
  end

  # ── Monday list ───────────────────────────────────────────────────────────

  def run_weekly(compcode)
    data     = Alerts::StaffDigest.new(compcode: compcode).call
    company  = MstCompany.find_by(cmp_companycode: compcode)
    renderer = Reports::StaffFollowupPdf.new(data: data, company: company)
    media_id = upload(renderer)

    to_fix = data[:not_recorded].size + data[:no_fingerprint].size

    sent = weekly_recipients.map do |number, name, _role|
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

  # ── morning list ──────────────────────────────────────────────────────────

  # Sent only on days there is somebody to talk to. Roughly 1.3 memberships end
  # per day and two days a week have none at all, so an unconditional daily
  # message would be empty often enough to teach staff to ignore the thread —
  # and the outage alert arrives on that same thread.
  def run_morning(compcode)
    data = Alerts::ExpiryDigest.new(compcode: compcode).call
    return log('no memberships finishing — nothing to send') if data[:total].zero?

    if sent_recently?(compcode, MORNING_TEMPLATE, 'MORN', 12.hours)
      return log('morning list already went out today')
    end

    values = [
      Alerts::ExpiryDigest.line(data[:ending_today]),
      Alerts::ExpiryDigest.line(data[:just_finished])
    ]

    sent = morning_recipients.map do |number, name, _role|
      deliver(compcode, MORNING_TEMPLATE, 'MORN', number, [name] + values)
    end

    summary = "morning list: #{sent.count(true)}/#{sent.size} sent, #{data[:total]} member(s)"
    log(summary)
    summary
  end

  # Only the people who are actually at the gym. Poonam is deliberately not on
  # this one — it is a desk worklist, not something she can act on from home —
  # so it goes to the :staff role, which is Vishal, Mani and Lakshay.
  def morning_recipients
    recipients.select { |_, _, role| role == :staff }.uniq { |number, _, _| number }
  end

  def plural(count)
    "#{count} member#{'s' if count != 1}"
  end

  # ── recipients ────────────────────────────────────────────────────────────

  # [number, greeting name, role]. A number may appear once per role, so one
  # person can be sent both wordings of the same outage.
  def recipients
    @recipients ||= begin
      rows = MstStaffList.where(id: staff_ids).index_by { |s| s.id.to_s }
      list = staff_ids.filter_map do |id|
        staff  = rows[id]
        next if staff.nil?

        number = staff.stf_contact.to_s.gsub(/\D/, '')
        next if number.length < 10

        [number, staff.stf_name.to_s.split.first.presence || 'there', :staff]
      end

      ENV.fetch('STAFF_ALERT_EXTRA', DEFAULT_EXTRA).split(',').each do |entry|
        number, name, role = entry.to_s.split(':', 3).map { |part| part.to_s.strip }
        next if number.blank?

        list << [number, name.presence || 'there', (role.presence || 'staff').to_sym]
      end

      list.uniq { |number, _, role| [number, role] }
    end
  end

  # The Monday list has one wording, so it goes out once per person however
  # many roles they hold — Lakshay is on the biometric alert twice but must not
  # get the same PDF twice.
  def weekly_recipients
    recipients.uniq { |number, _, _| number }
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

  def sent_recently?(compcode, template, kind_code, within = REPEAT_AFTER)
    TrnWhatsappLog
      .where(wl_compcode: compcode, wl_template_name: template, wl_subscription_id: kind_code)
      .where.not(wl_status: 'FAILED')
      .where('wl_sent_at >= ?', within.ago)
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
