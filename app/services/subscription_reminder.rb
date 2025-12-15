class SubscriptionReminder

  def self.send_all
    compcode = "SF"     # or loop all companies if multi-tenant

    expiring = TrnMemberSubscription.where(
      "ms_compcode = ? AND ms_end_date BETWEEN ? AND ?",
      compcode,
      Date.today,
      Date.today + 7
    )

    expiring.each do |sub|
      member = MstMembersList.where(id: sub.ms_member_id).first

      next if already_sent?(member.id, sub.id)

      msg = "Dear #{member.mmbr_name}, your gym membership expires on #{sub.ms_end_date}. Please renew soon."

      # WhatsApp
      WhatsappService.send_message(member.mmbr_contact, msg, ENV['WA_API_KEY'])

      # Log it
      log_sent(member.id, sub.id)
    end
  end

  def self.log_sent(member_id, subscription_id)
    ReminderLog.create(member_id: member_id, subscription_id: subscription_id)
  end

  def self.already_sent?(member_id, subscription_id)
    ReminderLog.where(member_id: member_id, subscription_id: subscription_id).exists?
  end
end
