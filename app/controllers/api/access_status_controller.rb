class Api::AccessStatusController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    compcode = params[:compcode]
    device_sn = params[:device_sn]
    today = Date.today

    mappings = TrnMemberBiometricMapping.where(
      mbm_compcode: compcode,
      mbm_device_sn: device_sn,
      mbm_is_active: 'Y'
    )

    users = mappings.map do |m|
      has_active = TrnMemberSubscription.where(
        ms_compcode: compcode,
        ms_member_id: m.mbm_member_id
      ).where('ms_end_date >= ?', today).exists?

      member = MstMembersList.find_by(id: m.mbm_member_id)

      # Removing a member revokes gym access even if the subscription they paid
      # for still has days left. Their mappings are deactivated at removal too;
      # this is the backstop in case one is still marked active.
      has_active = false if member.nil? || member.removed?

      {
        device_user_id: m.mbm_device_user_id,
        access: has_active ? "ALLOW" : "DENY",
        name: member&.mmbr_name || "Unknown",
        user_info: {
          uid: m.mbm_uid,
          device_user_id: m.mbm_device_user_id,
          name: member&.mmbr_name || "Unknown",
          templates: m.mbm_finger_template ? JSON.parse(m.mbm_finger_template) : nil
        }
      }
    end

    render json: { status: true, users: users }
  end
end