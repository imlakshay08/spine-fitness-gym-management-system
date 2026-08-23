class TrnWhatsappInbox < ApplicationRecord
  self.table_name = 'trn_whatsapp_inbox'

  scope :unreplied, -> { where(wi_replied: 0) }
  scope :recent, -> { order(wi_received_at: :desc) }
  scope :for_number, ->(number) { where(wi_from_number: number) }

  def member
    phone = wi_from_number.to_s.last(10)
    MstMembersList.find_by(mmbr_contact: phone)
  end

  def display_name
    member&.mmbr_name || wi_from_number
  end
end