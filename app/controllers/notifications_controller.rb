class NotificationsController < ApplicationController
  before_action :require_login

  # Polled by the bell in the header. Returns the current conditions, not a
  # list of past events, so there is nothing to mark as read here — an item
  # disappears when the thing it is about is fixed.
  def index
    feed = Notifications::Feed.new(compcode: session[:loggedUserCompCode]).call

    render json: feed
  rescue StandardError => e
    # The header sits on every page. A broken notification query must never be
    # able to take a screen down with it.
    Rails.logger.error "[Notifications] #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace&.first(5)&.join("\n")

    render json: { items: [], badge: 0, error: true }
  end
end
