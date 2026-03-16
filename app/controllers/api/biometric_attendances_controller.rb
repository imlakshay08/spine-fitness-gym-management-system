class Api::BiometricAttendancesController < ApplicationController
  skip_before_action :verify_authenticity_token
  #before_action :authenticate_bridge!

  def create
    compcode       = params[:compcode].to_s
    device_user_id = params[:user_id].to_i
    device_sn      = params[:device_sn].to_s
    punch_time = Time.zone.parse(params[:timestamp]) rescue Time.current

    # 1️⃣ Find biometric mapping
      mapping = TrnMemberBiometricMapping.find_by(
        mbm_compcode: compcode,
        mbm_device_user_id: device_user_id,
        mbm_device_sn: device_sn
      )

    unless mapping
      render json: {
        status: false,
        message: "Biometric user not mapped"
      }, status: 404
      return
    end

    member = mapping.member

    # 2️⃣ Ignore duplicate punches (same member, same minute)
    if duplicate_punch?(member.id, punch_time)
      render json: { status: true, message: "Duplicate ignored" }
      return
    end

    # 3️⃣ Subscription validation
    subscription = latest_subscription(member.id, compcode)

    if subscription && subscription.ms_end_date >= Date.today
      att_status = "ALLOWED"
      reason     = nil
    else
      att_status = "DENIED"
      reason     = "Subscription expired"
    end

    # 4️⃣ Store attendance
    TrnMemberAttendance.create!(
      att_compcode: compcode,
      att_member_id: member.id,
      att_device_user_id: device_user_id,
      att_device_sn: device_sn,
      att_punch_time: punch_time,
      att_punch_date: punch_time.to_date,
      att_status: att_status,
      att_reason: reason
    )

    render json: {
      status: true,
      access: att_status
    }
  end

  private

#   def authenticate_bridge!
#     token = request.headers["Authorization"]&.split(" ")&.last
#     head :unauthorized unless token == ENV["BIOMETRIC_API_TOKEN"]
#   end

  def duplicate_punch?(member_id, time)
    TrnMemberAttendance.where(
      att_member_id: member_id,
      att_punch_time: time.beginning_of_minute..time.end_of_minute
    ).exists?
  end

  def latest_subscription(member_id, compcode)
    TrnMemberSubscription
      .where(ms_compcode: compcode, ms_member_id: member_id)
      .order(ms_end_date: :desc)
      .first
  end
end
