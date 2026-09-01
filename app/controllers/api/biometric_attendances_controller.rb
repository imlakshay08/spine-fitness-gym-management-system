class Api::BiometricAttendancesController < ApplicationController
  DEVICE_ZONE = ActiveSupport::TimeZone['Asia/Kolkata'].freeze
  skip_before_action :verify_authenticity_token
  include BridgeAuthentication

def create
  compcode       = params[:compcode].to_s
  device_user_id = params[:user_id].to_s.strip
  device_sn      = params[:device_sn].to_s
  # The scanner sits in the gym and reports its own wall clock, which is IST.
  # Parsing with the ambient Time.zone was a coin flip: ApplicationController
  # mutates Time.zone to Kolkata in a few helpers, and Puma reuses threads, so
  # the same device produced rows 5h30m apart depending on what ran before it.
  punch_time     = (DEVICE_ZONE.parse(params[:timestamp]) rescue nil) || Time.current

  # Reject old punches
  if punch_time.to_date < Date.today
    render json: { status: true, message: "Old punch ignored" }
    return
  end

  # Find mapping
  mapping = TrnMemberBiometricMapping.find_by(
    mbm_compcode:       compcode,
    mbm_device_user_id: device_user_id,
    mbm_device_sn:      device_sn,
    mbm_is_active:      'Y'   # ← add this
  )

  unless mapping
    render json: { status: false, message: "Not mapped" }, status: 404
    return
  end

  # Find member directly — no association
  member = MstMembersList.find_by(
    id:            mapping.mbm_member_id,
    mmbr_compcode: compcode
  )

  unless member
    render json: { status: false, message: "Member not found" }, status: 404
    return
  end

  # Duplicate check
  if duplicate_punch?(member.id, punch_time)
    render json: { status: true, message: "Duplicate ignored" }
    return
  end

  # Subscription check
  subscription = latest_subscription(member.id, compcode)

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

  # Save attendance
  TrnMemberAttendance.create!(
    att_compcode:       compcode,
    att_member_id:      member.id.to_s,
    att_device_user_id: device_user_id,
    att_device_sn:      device_sn,
    att_punch_time:     punch_time,
    att_punch_date:     punch_time.to_date,
    att_status:         att_status,
    att_reason:         reason
  )

  render json: { status: true, access: att_status }
end

  private

  def duplicate_punch?(member_id, time)
    TrnMemberAttendance.where(
      att_member_id: member_id,
      att_punch_date: time.to_date  # one punch per day per member
    ).exists?
  end

  def latest_subscription(member_id, compcode)
    TrnMemberSubscription
      .where(ms_compcode: compcode, ms_member_id: member_id)
      .order(ms_end_date: :desc)
      .first
  end
end
