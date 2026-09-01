class Api::AdmsController < ApplicationController
  DEVICE_ZONE = ActiveSupport::TimeZone['Asia/Kolkata'].freeze
  skip_before_action :verify_authenticity_token
  before_action :verify_known_device


  def getrequest
   render plain: "OK"
  end

  def handshake
    render plain: "OK"
  end

  def receive
    body = request.body.read
    Rails.logger.info "ADMS received: #{body}"

    # Extract device SN from header line
    sn_match = body.match(/SN=([^\s&\r\n]+)/i)
    device_sn = sn_match ? sn_match[1] : ENV['DEVICE_SERIAL'].to_s

    body.each_line do |line|
      line = line.strip
      next if line.empty?
      next if line.start_with?("ATTLOG")  # skip header line

      parts = line.split("\t")
      next unless parts.length >= 2

      device_user_id = parts[0].to_s.strip
      timestamp      = parts[1].to_s.strip

      # Skip non-data lines (letters only = header/command, not a punch)
      next unless device_user_id.match?(/\A\d+\z/)

      # Device clock is IST; never rely on the ambient Time.zone here.
      punch_time = DEVICE_ZONE.parse(timestamp) rescue nil
      next unless punch_time
      next if punch_time.to_date < Date.today

      process_attendance(device_user_id, punch_time, device_sn)
    end

    render plain: "OK"
  end

  private
  # The ZKTeco push protocol has no way to send a bearer token, so the serial
  # the device reports is the only thing available to check. Set DEVICE_SERIALS
  # (comma separated) to restrict these endpoints to your own hardware; leave
  # it unset and every call is allowed but logged, exactly as before.
  #
  # If attendance only ever arrives through the Python bridge, this path is
  # unused: set DEVICE_SERIALS to a value no device reports, or drop the
  # /iclock routes, to close it entirely.
  def verify_known_device
    allowed = ENV['DEVICE_SERIALS'].to_s.split(',').map(&:strip).reject(&:empty?)
    return true if allowed.empty?

    reported = request.query_parameters['SN'].presence ||
               request.raw_post.to_s[/SN=([^\s&
]+)/i, 1]

    return true if reported.present? && allowed.include?(reported)

    Rails.logger.warn "[ADMS] REJECTED #{request.path} from #{request.remote_ip} (SN=#{reported.inspect})"
    head :unauthorized
    false
  end

  def process_attendance(device_user_id, punch_time, device_sn)
    mapping = TrnMemberBiometricMapping.find_by(
      mbm_compcode:       'SF',
      mbm_device_user_id: device_user_id,
      mbm_device_sn:      device_sn          # ← dynamic now
    )
    return unless mapping

    member = MstMembersList.find_by(
      id:            mapping.mbm_member_id,
      mmbr_compcode: 'SF'
    )
    return unless member

    already_exists = TrnMemberAttendance.where(
      att_member_id:  member.id.to_s,
      att_punch_time: punch_time.beginning_of_minute..punch_time.end_of_minute
    ).exists?
    return if already_exists

    subscription = TrnMemberSubscription
      .where(ms_compcode: 'SF', ms_member_id: member.id.to_s)
      .order(ms_end_date: :desc)
      .first

    if member.removed?
      # Taken off the member list: no entry, whatever the subscription says.
      att_status = "DENIED"
      reason     = "Member removed"
    elsif subscription && subscription.ms_end_date >= Date.today
      att_status = "ALLOWED"
      reason     = "Y"
    else
      att_status = "DENIED"
      reason     = "Subscription expired"
    end

    TrnMemberAttendance.create!(
      att_compcode:       'SF',
      att_member_id:      member.id.to_s,
      att_device_user_id: device_user_id,
      att_device_sn:      device_sn,          # ← dynamic now
      att_punch_time:     punch_time,
      att_punch_date:     punch_time.to_date,
      att_status:         att_status,
      att_reason:         reason
    )

    Rails.logger.info "ADMS Attendance: #{member.mmbr_name} - #{att_status}"
  end
end