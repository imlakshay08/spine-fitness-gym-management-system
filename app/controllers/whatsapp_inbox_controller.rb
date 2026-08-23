class WhatsappInboxController < ApplicationController
  def index
    all_messages = TrnWhatsappInbox
      .where(wi_compcode: 'SF')
      .order(wi_received_at: :desc)

    # Group into conversations by phone number
    @conversations = all_messages
      .group_by(&:wi_from_number)
      .map do |number, messages|
        last_msg = messages.first
        member   = MstMembersList.find_by(mmbr_contact: number.to_s.last(10))
        {
          number:       number,
          name:         member&.mmbr_name || number,
          last_message: last_msg.wi_body,
          last_time:    last_msg.wi_received_at,
          unread:       messages.count { |m| m.wi_replied == 0 },
          messages:     messages.sort_by(&:wi_received_at)
        }
      end
      .sort_by { |c| -c[:last_time].to_i }

    @active_number = params[:number] || @conversations.first&.dig(:number)

    @active_chat = @conversations.find { |c| c[:number] == @active_number }

    @total_unreplied = @conversations.sum { |c| c[:unread] }
  end

  def reply
    @inbox     = TrnWhatsappInbox.find(params[:id])
    reply_text = params[:reply_text]

    if reply_text.blank?
      redirect_to whatsapp_inbox_index_path(number: @inbox.wi_from_number),
        alert: "Reply cannot be blank"
      return
    end

    response = Meta::SendWhatsapp.send_text(
      phone: @inbox.wi_from_number,
      message: reply_text
    )

    if response[:http_code].between?(200, 299)
      # Mark all messages from this number as replied
      TrnWhatsappInbox
        .where(wi_compcode: 'SF', wi_from_number: @inbox.wi_from_number, wi_replied: 0)
        .update_all(
          wi_replied:    1,
          wi_replied_at: Time.current,
          wi_replied_by: session[:loggedUserName] || 'Staff',
          wi_reply_text: reply_text,
          updated_at:    Time.current
        )

      redirect_to whatsapp_inbox_index_path(number: @inbox.wi_from_number),
        notice: "Sent!"
    else
      redirect_to whatsapp_inbox_index_path(number: @inbox.wi_from_number),
        alert: "Failed to send. Try again."
    end
  end
end
