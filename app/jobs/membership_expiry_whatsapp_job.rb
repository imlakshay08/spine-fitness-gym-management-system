class MembershipExpiryWhatsappJob < ApplicationJob
  queue_as :default

  def perform(type = :expiring)
    compcode = "SF"
    today = Date.today

    subscriptions =
      case type
      when :expiring
        TrnMemberSubscription.where(
          ms_compcode: compcode,
          ms_end_date: today + 3.days,
          ms_status: "ACTIVE"
        )
      when :expired
        TrnMemberSubscription.where(
              ms_compcode: compcode,
              ms_status: "ACTIVE",
              ms_end_date: 7.days.ago.to_date..(today - 1)
            )

      end

      subscriptions.find_each do |sub|
      member = MstMembersList.find_by(id: sub.ms_member_id)
      next if member.nil? || member.mmbr_contact.blank?

      template = case type
                  when :expiring then "membership_expiry_reminder"
                  when :expired  then "membership_expired_alert"
                  end

      already_sent = TrnWhatsappLog.where(
        wl_subscription_id: sub.id,
        wl_template_name: template,
        wl_status: %w[DELIVERED READ]
      ).exists?

      next if already_sent

# Line 1
      response = Meta::SendWhatsapp.send_template(
        phone: member.mmbr_contact,
        template: template,
        body_values: [member.mmbr_name, sub.ms_end_date.strftime("%d %b %Y")]
      )

      # Line 2
      success =
        response[:http_code].between?(200, 299) &&
        response.dig(:body, "messages")&.first&.dig("id").present?

      TrnWhatsappLog.create!(
        wl_compcode: compcode,
        wl_member_id: member.id,
        wl_subscription_id: sub.id,
        wl_template_name: template,
        wl_sent_at: Time.current,
        wl_status: success ? "QUEUED" : "FAILED",
        wl_interakt_msg_id: response.dig(:body, "messages", 0, "id"),
        wl_api_response: response[:raw],
        wl_failed_reason: response[:raw]
      )

    end
  end
end
