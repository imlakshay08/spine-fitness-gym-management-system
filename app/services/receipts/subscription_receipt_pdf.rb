module Receipts
  # Payment receipt for a membership subscription, attached to the WhatsApp
  # confirmation as a document.
  #
  # Prawn 1.2.1 ships only the built-in AFM fonts, which cannot encode the
  # rupee sign — "₹" is silently rewritten to "_". Every amount therefore
  # prints as "Rs." rather than corrupting the receipt.
  class SubscriptionReceiptPdf
    RUPEE = 'Rs.'.freeze

    INK        = '1F2D3D'.freeze
    MUTED      = '8A8F9A'.freeze
    ACCENT     = 'FF5A1F'.freeze
    RULE       = 'DDE1E6'.freeze
    PANEL      = 'F5F6F8'.freeze

    def initialize(subscription:, member:, plan: nil, payment: nil, company: nil)
      @subscription = subscription
      @member       = member
      @plan         = plan
      @payment      = payment
      @company      = company
    end

    # Returns the PDF as a binary string.
    def render
      pdf = Prawn::Document.new(page_size: 'A4', margin: [36, 40, 40, 40])
      pdf.font 'Helvetica'
      pdf.fill_color INK

      letterhead(pdf)
      title_bar(pdf)
      parties(pdf)
      line_items(pdf)
      total(pdf)
      footer(pdf)

      pdf.render
    end

    # Writes the PDF to disk and returns the path. Meta's media upload needs a
    # real file handle, so the caller gets a tempfile it is expected to clean up.
    def write_to(path)
      File.binwrite(path, render)
      path
    end

    def filename
      "Receipt-#{receipt_no}.pdf"
    end

    private

    def letterhead(pdf)
      pdf.text 'SPINE FITNESS', size: 22, style: :bold, color: ACCENT
      pdf.move_down 2

      [company_name, address_line, contact_line].compact_blank.each do |line|
        pdf.text line, size: 8.5, color: MUTED
      end

      pdf.move_down 14
      pdf.stroke_color RULE
      pdf.stroke_horizontal_rule
      pdf.move_down 16
    end

    def title_bar(pdf)
      pdf.fill_color INK
      pdf.text 'PAYMENT RECEIPT', size: 13, style: :bold, character_spacing: 1.2

      pdf.move_down 6
      pdf.text "Receipt No.  #{receipt_no}", size: 9.5, color: MUTED
      pdf.text "Date         #{issued_on}", size: 9.5, color: MUTED
      pdf.move_down 16
    end

    def parties(pdf)
      pdf.fill_color MUTED
      pdf.text 'RECEIVED FROM', size: 8, style: :bold, character_spacing: 0.8
      pdf.move_down 4

      pdf.fill_color INK
      pdf.text @member.mmbr_name.to_s, size: 12, style: :bold
      pdf.move_down 2

      details = []
      details << "Member ID: #{@member.mmbr_code}" if @member.mmbr_code.present?
      details << "Mobile: #{@member.mmbr_contact}" if @member.mmbr_contact.present?
      pdf.text details.join('    '), size: 9, color: MUTED if details.any?

      pdf.move_down 18
    end

    def line_items(pdf)
      rows = [
        ['DESCRIPTION', 'PERIOD', 'AMOUNT'],
        [plan_description, validity_period, money(gross_amount)]
      ]

      pdf.table(rows, width: pdf.bounds.width, cell_style: { border_width: 0, padding: [9, 10, 9, 10] }) do |t|
        t.row(0).background_color = PANEL
        t.row(0).text_color       = MUTED
        t.row(0).size             = 8
        t.row(0).font_style       = :bold
        t.row(1).size             = 10
        t.row(1).borders          = [:bottom]
        t.row(1).border_color     = RULE
        t.columns(2).align        = :right
        t.column(0).width         = pdf.bounds.width * 0.42
        t.column(2).width         = pdf.bounds.width * 0.22
      end

      pdf.move_down 4
      return if discount_amount <= 0

      summary_line(pdf, 'Plan amount', money(gross_amount))
      summary_line(pdf, 'Discount',    "- #{money(discount_amount)}")
    end

    def summary_line(pdf, label, value)
      pdf.move_down 6
      pdf.text_box label, at: [pdf.bounds.width - 240, pdf.cursor], width: 150, size: 9, color: MUTED, align: :right
      pdf.text_box value, at: [pdf.bounds.width -  90, pdf.cursor], width:  90, size: 9, align: :right
      pdf.move_down 4
    end

    def total(pdf)
      pdf.move_down 10
      top = pdf.cursor

      pdf.fill_color PANEL
      pdf.fill_rounded_rectangle [pdf.bounds.width - 260, top], 260, 44, 4
      pdf.fill_color INK

      pdf.text_box 'TOTAL PAID', at: [pdf.bounds.width - 244, top - 12],
                   width: 110, size: 9, style: :bold, color: MUTED
      pdf.text_box money(amount_paid), at: [pdf.bounds.width - 140, top - 10],
                   width: 124, size: 15, style: :bold, align: :right

      pdf.text_box "Paid by #{payment_mode}", at: [pdf.bounds.width - 244, top - 30],
                   width: 228, size: 8.5, color: MUTED

      pdf.move_down 62
    end

    def footer(pdf)
      pdf.stroke_color RULE
      pdf.stroke_horizontal_rule
      pdf.move_down 10

      pdf.fill_color INK
      pdf.text 'Thank you for training with Spine Fitness.', size: 10, style: :bold
      pdf.move_down 3
      pdf.fill_color MUTED
      pdf.text 'Please keep this receipt for your records. This is a computer generated ' \
               'receipt and does not require a signature.', size: 8
    end

    # ── values ──────────────────────────────────────────────────────────────

    def receipt_no
      @payment&.pay_no.presence || @subscription.ms_sbscrptn_no.to_s
    end

    def issued_on
      date = @payment&.pay_date || @subscription.ms_start_date
      date.respond_to?(:strftime) ? date.strftime('%d %b %Y') : Date.current.strftime('%d %b %Y')
    end

    def plan_description
      name = @plan&.plan_name.presence || 'Gym Membership'
      months = @plan&.plan_duration_months.to_i
      months > 0 ? "#{name} membership (#{months} #{'month'.pluralize(months)})" : "#{name} membership"
    end

    def validity_period
      "#{fmt(@subscription.ms_start_date)}  to  #{fmt(@subscription.ms_end_date)}"
    end

    def fmt(date)
      date.respond_to?(:strftime) ? date.strftime('%d %b %Y') : date.to_s
    end

    def gross_amount
      @subscription.ms_plan_amount.to_f.positive? ? @subscription.ms_plan_amount.to_f : amount_paid
    end

    def discount_amount
      @subscription.ms_discount_amount.to_f
    end

    def amount_paid
      @subscription.ms_amount_paid.to_f
    end

    def payment_mode
      (@payment&.pay_mode.presence || @subscription.ms_payment_mode.presence || 'Cash').to_s.upcase
    end

    def money(value)
      "#{RUPEE} #{ActiveSupport::NumberHelper.number_to_delimited(format('%.2f', value.to_f), delimiter: ',')}"
    end

    def company_name
      @company&.cmp_companyname.presence
    end

    def address_line
      [@company&.cmp_addressline1, @company&.cmp_addressline2].compact_blank.join(', ').presence
    end

    def contact_line
      bits = []
      bits << "Phone: #{@company.cmp_cell_number}" if @company&.cmp_cell_number.present? && @company.cmp_cell_number.to_s != '0'
      bits << "Email: #{@company.cmp_email}"       if @company&.cmp_email.present?
      bits.join('    ').presence
    end
  end
end
