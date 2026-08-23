class MstMembersList < ApplicationRecord
  # A member is never deleted — subscriptions, payments and WhatsApp logs all
  # point here by id, and removing the row turns those into "Unknown member".
  # Staff "remove" instead, which hides the member from lists and pickers while
  # every historical record still resolves to a name.
  STATUS_ON_ROLL = 'A'.freeze
  STATUS_REMOVED = 'R'.freeze

  # Deliberately not a default_scope: lookups by id must keep finding removed
  # members. Only lists and pickers narrow down with .on_roll.
  scope :on_roll, -> { where(mmbr_status: STATUS_ON_ROLL) }
  scope :removed, -> { where(mmbr_status: STATUS_REMOVED) }

  def removed?
    mmbr_status.to_s.upcase == STATUS_REMOVED
  end

  def on_roll?
    !removed?
  end
end
