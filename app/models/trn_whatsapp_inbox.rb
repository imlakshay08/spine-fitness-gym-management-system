class TrnWhatsappInbox < ApplicationRecord
  self.table_name = 'trn_whatsapp_inbox'

  DIRECTION_IN  = 'IN'.freeze
  DIRECTION_OUT = 'OUT'.freeze

  # Meta only allows free-form (non-template) text inside 24h of the member's
  # last message. After that the send fails with error 131047.
  SESSION_WINDOW = 24.hours

  scope :inbound,    -> { where(wi_direction: DIRECTION_IN) }
  scope :outbound,   -> { where(wi_direction: DIRECTION_OUT) }
  scope :unseen,     -> { inbound.where(wi_seen_at: nil) }
  scope :unreplied,  -> { where(wi_replied: 0) }
  scope :recent,     -> { order(wi_received_at: :desc) }
  scope :for_number, ->(number) { where(wi_from_number: number) }

  def inbound?
    wi_direction.to_s.upcase != DIRECTION_OUT
  end

  def outbound?
    !inbound?
  end

  # "+91 98719 46454", "9871946454", "919871946454" all resolve to the same
  # thread key so a member never shows up twice in the sidebar.
  def self.normalize_number(raw)
    digits = raw.to_s.gsub(/\D/, '')
    return nil if digits.length < 10
    "91#{digits.last(10)}"
  end

  def member
    phone = wi_from_number.to_s.last(10)
    MstMembersList.find_by(mmbr_contact: phone)
  end

  def display_name
    wi_member_name.presence || member&.mmbr_name || wi_from_number
  end
end
