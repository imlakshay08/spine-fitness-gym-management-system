class Api::MemberMappingsController < ApplicationController
  skip_before_action :verify_authenticity_token
  include BridgeAuthentication

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
      member = members_map[m.mbm_member_id.to_s]
      # A member taken off the list loses access regardless of what they paid for.
      allowed = active_member_ids.include?(m.mbm_member_id.to_s) && member.present? && member.on_roll?

      {
        mapping_id:        m.id,
        member_id:         m.mbm_member_id,
        member_name:       member&.mmbr_name || "Unknown",
        device_user_id:    m.mbm_device_user_id,
        uid:               m.mbm_uid,
        is_active_mapping: m.mbm_is_active == 'Y',
        access:            allowed ? "ALLOW" : "DENY",
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

 # in Api::MemberMappingsController
  def max_ids
    max_uid     = TrnMemberBiometricMapping.where(mbm_compcode: params[:compcode], mbm_device_sn: params[:device_sn]).maximum(:mbm_uid).to_i
    max_user_id = TrnMemberBiometricMapping.where(mbm_compcode: params[:compcode], mbm_device_sn: params[:device_sn]).maximum("CAST(mbm_device_user_id AS UNSIGNED)").to_i
    render json: { status: true, max_uid: max_uid, max_device_user_id: max_user_id }
  end

  def sync_needed
  compcode = params[:compcode].to_s

  # Check if any subscription was renewed/created in the last 2 minutes
  # AND is currently active (end_date >= today)
  recently_renewed = TrnMemberSubscription
    .where(ms_compcode: compcode)
    .where('ms_end_date >= ?', Date.today)
    .where('updated_at >= ?', 2.minutes.ago)
    .exists?

  render json: { sync_needed: recently_renewed }
end
end