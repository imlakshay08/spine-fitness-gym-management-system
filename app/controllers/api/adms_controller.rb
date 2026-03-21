class Api::AdmsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def handshake
    render plain: "OK"
  end

  def receive
    body = request.body.read
    Rails.logger.info "ADMS received: #{body}"

    body.each_line do |line|
      line = line.strip
      next unless line.start_with?("ATTLOG")

      parts = line.split("\t")
      next unless parts.length >= 3

      device_user_id = parts[1].to_s.strip
      timestamp      = parts[2].to_s.strip
      punch_time     = Time.zone.parse(timestamp) rescue nil
      next unless punch_time

      next if punch_time.to_date < Date.today

      process_attendance(device_user_id, punch_time)
    end

    render plain: "OK"
  end

  private

  def process_attendance(device_user_id, punch_time)
    mapping = TrnMemberBiometricMapping.find_by(
      mbm_compcode:       'SF',
      mbm_device_user_id: device_user_id,
      mbm_device_sn:      'NFZ8253402448'
    )
    return unless mapping

    member = MstMembersList.find_by(
      id:            mapping.mbm_member_id,
      mmbr_compcode: 'SF'
    )
    return unless member

    already_exists = TrnMemberAttendance.where(
      att_member_id: member.id.to_s,
      att_punch_time: punch_time.beginning_of_minute..punch_time.end_of_minute
    ).exists?
    return if already_exists

    subscription = TrnMemberSubscription
      .where(ms_compcode: 'SF', ms_member_id: member.id.to_s)
      .order(ms_end_date: :desc)
      .first

    if subscription && subscription.ms_end_date >= Date.today
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
      att_device_sn:      'NFZ8253402448',
      att_punch_time:     punch_time,
      att_punch_date:     punch_time.to_date,
      att_status:         att_status,
      att_reason:         reason
    )

    Rails.logger.info "ADMS Attendance: #{member.mmbr_name} - #{att_status}"
  end
end