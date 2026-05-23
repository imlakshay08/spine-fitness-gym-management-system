class Api::AllMappingsController < ApplicationController
  skip_before_action :verify_authenticity_token
  #before_action :authenticate_bridge!

    def all_mappings
    mappings = TrnMemberBiometricMapping.where(
        mbm_compcode:  params[:compcode],
        mbm_device_sn: params[:device_sn],
        mbm_is_active: 'Y'
    )
    render json: {
        status: true,
        mappings: mappings.map { |m| {
        id:             m.id,
        member_id:      m.mbm_member_id,
        device_user_id: m.mbm_device_user_id,
        uid:            m.mbm_uid
        }}
    }
    end
end