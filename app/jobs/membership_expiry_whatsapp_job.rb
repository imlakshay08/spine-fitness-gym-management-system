class MembershipExpiryWhatsappJob < ApplicationJob
  queue_as :default

  TEMPLATE_NAME = "membership_expiry_reminder"

  def perform
    compcode = "SF"
    target_date = Date.today + 3.days

    subscriptions = TrnMemberSubscription
      .joins("INNER JOIN mst_members_lists ON mst_members_lists.id = trn_member_subscriptions.ms_member_id")
      .where(
        ms_compcode: compcode,
        ms_end_date: target_date,
        ms_status: "ACTIVE"
      )

    subscriptions.each do |sub|
      member = MstMembersList.find(sub.ms_member_id)
      next if member.mmbr_contact.blank?

      already_sent = TrnWhatsappLog.exists?(
        wl_compcode: compcode,
        wl_member_id: member.id,
        wl_subscription_id: sub.id,
        wl_template_name: TEMPLATE_NAME
      )

      next if already_sent

      response = Interakt::SendWhatsapp.send_membership_expiry(
        phone: member.mmbr_contact,
        name: member.mmbr_name,
        expiry_date: sub.ms_end_date
      )

      TrnWhatsappLog.create!(
        wl_compcode: compcode,
        wl_member_id: member.id,
        wl_subscription_id: sub.id,
        wl_template_name: TEMPLATE_NAME,
        wl_sent_at: Time.current,
        wl_status: response&.code.to_i == 200 ? "SENT" : "FAILED",
        wl_api_response: response&.body.to_s
      )
    end
  end
end
