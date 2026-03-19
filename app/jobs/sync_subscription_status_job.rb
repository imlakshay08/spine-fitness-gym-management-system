class SyncSubscriptionStatusJob < ApplicationJob
  queue_as :default

  def perform
    today = Date.today

    expired_count = TrnMemberSubscription
      .where("ms_end_date < ? AND ms_status = ?", today, "ACTIVE")
      .update_all(ms_status: "EXPIRED", updated_at: Time.now)

    Rails.logger.info "[SyncSubscriptionStatusJob] #{Time.now} - Marked EXPIRED: #{expired_count}"
  end
end