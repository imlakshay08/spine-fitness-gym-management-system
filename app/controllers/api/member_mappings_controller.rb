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

  def device_audit
    compcode  = params[:compcode]
    device_sn = params[:device_sn]
    today     = Date.today

    mappings = TrnMemberBiometricMapping.where(
      mbm_compcode:  compcode,
      mbm_device_sn: device_sn
    )

    member_ids = mappings.map(&:mbm_member_id).uniq

    active_member_ids = TrnMemberSubscription
      .where(ms_compcode: compcode, ms_member_id: member_ids)
      .where('ms_end_date >= ?', today)
      .pluck(:ms_member_id)
      .map(&:to_s)
      .to_set

    members_map = MstMembersList
      .where(mmbr_compcode: compcode, id: member_ids)
      .index_by { |m| m.id.to_s }

    results = mappings.map do |m|
      {
        mapping_id:        m.id,
        member_id:         m.mbm_member_id,
        member_name:       members_map[m.mbm_member_id.to_s]&.mmbr_name || "Unknown",
        device_user_id:    m.mbm_device_user_id,
        uid:               m.mbm_uid,
        is_active_mapping: m.mbm_is_active == 'Y',
        access:            active_member_ids.include?(m.mbm_member_id.to_s) ? "ALLOW" : "DENY",
        templates:         m.mbm_finger_template.present? ? JSON.parse(m.mbm_finger_template) : nil
      }
    end

    render json: { status: true, mappings: results }
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