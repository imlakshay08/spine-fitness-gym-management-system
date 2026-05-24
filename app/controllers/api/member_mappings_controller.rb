class Api::MemberMappingsController < ApplicationController
  skip_before_action :verify_authenticity_token
  #before_action :authenticate_bridge!

  # GET /api/member_mappings — fetch all active mappings for a member
    def index
    mappings = TrnMemberBiometricMapping.where(
        mbm_compcode:  params[:compcode],
        mbm_member_id: params[:member_id].to_s,
        mbm_is_active: 'Y'
    ).select(:id, :mbm_device_user_id, :mbm_uid)

    render json: {
        status: true,
        mappings: mappings.map { |m| { id: m.id, device_user_id: m.mbm_device_user_id, uid: m.mbm_uid } }
    }
    end

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

    # POST /api/member_mappings/deactivate_all — deactivate all mappings for member
    def deactivate_all
      member_id = params[:member_id].to_s.strip
      compcode  = params[:compcode].to_s.strip

      Rails.logger.info "deactivate_all called: compcode=#{compcode} member_id=#{member_id}"

      count = TrnMemberBiometricMapping.where(
        mbm_compcode:  compcode,
        mbm_member_id: member_id,
        mbm_is_active: 'Y'
      ).update_all(mbm_is_active: 'N')

      Rails.logger.info "deactivate_all: updated #{count} rows"

      render json: { status: true, updated: count }
    end

    def deactivate
  mapping = TrnMemberBiometricMapping.find_by(id: params[:mapping_id])
  if mapping
    mapping.update(mbm_is_active: 'N')
    render json: { status: true }
  else
    render json: { status: false, message: "Not found" }
  end
 end
end