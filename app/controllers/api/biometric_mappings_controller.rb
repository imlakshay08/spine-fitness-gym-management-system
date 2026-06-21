class Api::BiometricMappingsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def allocate_ids
    compcode  = params[:compcode]
    device_sn = params[:device_sn]
    uid = nil
    device_user_id = nil

    ActiveRecord::Base.transaction do
      row = BiometricIdAllocation
        .lock("FOR UPDATE")
        .find_or_create_by!(
          allocation_compcode: compcode,
          allocation_device_sn: device_sn
        ) do |r|
          r.allocation_next_uid = 1
          r.allocation_next_device_user_id = 1
        end

      uid = row.allocation_next_uid
      device_user_id = row.allocation_next_device_user_id

      row.update!(
        allocation_next_uid: uid + 1,
        allocation_next_device_user_id: device_user_id + 1
      )
    end

    render json: { status: true, uid: uid, device_user_id: device_user_id.to_s }
  end
  
  def create
  mapping = TrnMemberBiometricMapping.create!(
    mbm_compcode:       params[:compcode],
    mbm_member_id:      params[:member_id].to_s,
    mbm_device_user_id: params[:device_user_id].to_s,
    mbm_device_sn:      params[:device_sn],
    mbm_uid:            params[:uid],
    mbm_is_active:      'Y'
  )
  render json: { status: true, mapping_id: mapping.id }
  rescue => e
   render json: { status: false, message: e.message }, status: 422
  end
  def save_template
    mapping = TrnMemberBiometricMapping.find_by(
      mbm_compcode:       params[:compcode],
      mbm_device_user_id: params[:device_user_id],
      mbm_device_sn:      params[:device_sn],
      mbm_is_active:      'Y'
    )
    return render json: { status: false, message: "Mapping not found" } unless mapping

    mapping.update(
      mbm_uid:             params[:uid],
      mbm_finger_template: params[:templates].to_json
    )
    render json: { status: true, mapping_id: mapping.id }
  end
end