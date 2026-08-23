require 'tempfile'

# Sends the member a WhatsApp confirmation with their receipt attached, the
# moment a subscription is created or renewed.
#
# Business-initiated, so it must go out as an approved template — the member
# has almost never messaged the gym, so there is no 24-hour customer service
# window to send free-form text in. The template carries a document header
# (the PDF) plus the body text, so it lands as one message.
#
# Runs async: staff should not wait on PDF generation and two Meta round trips
# while saving a subscription.
class SubscriptionReceiptWhatsappJob < ApplicationJob
  queue_as :default

  TEMPLATE = 'subscription_receipt'.freeze

  def perform(subscription_id, compcode = 'SF')
    subscription = TrnMemberSubscription.find_by(id: subscription_id, ms_compcode: compcode)
    return log_skip(subscription_id, 'subscription not found') if subscription.nil?

    member = MstMembersList.find_by(id: subscription.ms_member_id, mmbr_compcode: compcode)
    return log_skip(subscription_id, 'member not found')       if member.nil?
    return log_skip(subscription_id, 'member removed')         if member.removed?
    return log_skip(subscription_id, 'member has no contact')  if member.mmbr_contact.blank?

    # Guard against a double send if the save path ever fires twice.
    if TrnWhatsappLog.where(wl_compcode: compcode,
                            wl_subscription_id: subscription.id.to_s,
                            wl_template_name: TEMPLATE)
                     .where.not(wl_status: 'FAILED').exists?
      return log_skip(subscription_id, 'receipt already sent')
    end

    plan    = MstMembershipPlan.find_by(id: subscription.ms_plan_id)
    payment = TrnPayment.find_by(pay_compcode: compcode,
                                 pay_ref_type: 'MEMBER_SUBSCRIPTION',
                                 pay_ref_id: subscription.id)
    company = MstCompany.find_by(cmp_companycode: compcode)

    receipt = Receipts::SubscriptionReceiptPdf.new(
      subscription: subscription, member: member,
      plan: plan, payment: payment, company: company
    )

    media    = upload_receipt(receipt)
    media_id = media.dig(:body, 'id')

    body_values = build_body_values(subscription, member, plan, payment)

    # A failed upload must not cost the member their confirmation — send the
    # text on its own rather than dropping the message entirely.
    response = Meta::SendWhatsapp.send_template(
      phone:       member.mmbr_contact,
      template:    TEMPLATE,
      body_values: body_values,
      document:    media_id.present? ? { id: media_id, filename: receipt.filename } : nil
    )

    success = response[:http_code].to_i.between?(200, 299) &&
              response.dig(:body, 'messages', 0, 'id').present?

    TrnWhatsappLog.create!(
      wl_compcode:        compcode,
      wl_member_id:       member.id,
      wl_subscription_id: subscription.id,
      wl_template_name:   TEMPLATE,
      wl_message_body:    WhatsappTemplates.render(TEMPLATE, *body_values),
      wl_sent_at:         Time.current,
      wl_status:          success ? 'QUEUED' : 'FAILED',
      wl_interakt_msg_id: response.dig(:body, 'messages', 0, 'id'),
      wl_api_response:    response[:raw],
      wl_failed_reason:   success ? nil : failure_reason(response, media)
    )

    Rails.logger.info "[SubscriptionReceipt] #{member.mmbr_name} sub=#{subscription.id} " \
                      "pdf=#{media_id.present? ? 'attached' : 'MISSING'} sent=#{success}"
  ensure
    cleanup(@tempfile)
  end

  private

  def upload_receipt(receipt)
    @tempfile = Tempfile.new(['receipt', '.pdf'])
    @tempfile.binmode
    @tempfile.write(receipt.render)
    @tempfile.flush
    @tempfile.close

    Meta::SendWhatsapp.upload_media(file_path: @tempfile.path, mime_type: 'application/pdf')
  rescue StandardError => e
    Rails.logger.error "[SubscriptionReceipt] receipt build/upload failed: #{e.class}: #{e.message}"
    { http_code: 0, body: {}, raw: "#{e.class}: #{e.message}" }
  end

  # Must stay in the same order as the {{1}}..{{7}} placeholders approved in
  # Meta and declared in WhatsappTemplates.
  def build_body_values(subscription, member, plan, payment)
    [
      member.mmbr_name.to_s,
      payment&.pay_no.presence || subscription.ms_sbscrptn_no.to_s,
      plan&.plan_name.presence || 'Gym Membership',
      amount(subscription.ms_amount_paid),
      (payment&.pay_mode.presence || subscription.ms_payment_mode.presence || 'Cash').to_s.upcase,
      fmt(subscription.ms_start_date),
      fmt(subscription.ms_end_date)
    ]
  end

  # Whole rupees read better in a chat line ("Rs. 15,000"); paise are only
  # shown when there actually are any. The PDF keeps 2dp throughout.
  def amount(value)
    number = value.to_f
    text   = (number % 1).zero? ? format('%d', number) : format('%.2f', number)
    ActiveSupport::NumberHelper.number_to_delimited(text, delimiter: ',')
  end

  def fmt(date)
    date.respond_to?(:strftime) ? date.strftime('%d %b %Y') : date.to_s
  end

  def failure_reason(response, media)
    response.dig(:body, 'error', 'message').presence ||
      media.dig(:body, 'error', 'message').presence ||
      "Send failed (HTTP #{response[:http_code]})"
  end

  def cleanup(tempfile)
    return if tempfile.nil?
    tempfile.close unless tempfile.closed?
    tempfile.unlink
  rescue StandardError
    nil
  end

  def log_skip(subscription_id, reason)
    Rails.logger.info "[SubscriptionReceipt] sub=#{subscription_id} skipped — #{reason}"
    nil
  end
end
