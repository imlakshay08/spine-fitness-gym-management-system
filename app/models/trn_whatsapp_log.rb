class TrnWhatsappLog < ApplicationRecord
  STATUSES = %w[QUEUED SENT DELIVERED READ FAILED].freeze

  validates :wl_status, inclusion: { in: STATUSES }
  validates :wl_template_name, presence: true
end
