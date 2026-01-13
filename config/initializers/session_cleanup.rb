# Runs only once per deploy
if ENV["SESSION_CLEANUP_ON_BOOT"] == "true"
  Rails.logger.info "Running session cleanup..."

  ActiveRecord::SessionStore::Session
    .where("updated_at < ?", 2.days.ago)
    .delete_all

  Rails.logger.info "Session cleanup done"
end
