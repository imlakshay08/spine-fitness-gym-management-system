class WhatsappInboxController < ApplicationController
  def index
    @messages = TrnWhatsappInbox
      .where(wi_compcode: 'SF')
      .recent
      .limit(100)

    @unreplied_count = TrnWhatsappInbox
      .where(wi_compcode: 'SF')
      .unreplied
      .count
  end

  def reply
    @inbox = TrnWhatsappInbox.find(params[:id])
    reply_text = params[:reply_text]

    if reply_text.blank?
      redirect_to whatsapp_inbox_index_path, alert: "Reply cannot be blank"
      return
    end

    # Send reply via Meta API
    response = Meta::SendWhatsapp.send_text(
      phone: @inbox.wi_from_number,
      message: reply_text
    )

    if response[:http_code].between?(200, 299)
      @inbox.update!(
        wi_replied:    1,
        wi_replied_at: Time.current,
        wi_replied_by: session[:loggedUserName] || 'Staff',
        wi_reply_text: reply_text
      )
      redirect_to whatsapp_inbox_index_path,
        notice: "Reply sent to #{@inbox.display_name}!"
    else
      redirect_to whatsapp_inbox_index_path,
        alert: "Failed to send reply. Try again."
    end
  end
end