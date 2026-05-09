class Api::BiometricMappingsController < ApplicationController
  skip_before_action :verify_authenticity_token

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
      mbm_device_sn:      params[:device_sn]
    )
    return render json: { status: false, message: "Mapping not found" } unless mapping

    mapping.update(
      mbm_uid:             params[:uid],
      mbm_finger_template: params[:templates].to_json
    )

    render json: { status: true }
  end
end