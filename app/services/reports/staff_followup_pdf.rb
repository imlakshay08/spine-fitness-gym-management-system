module Reports
  # The Monday list for floor staff. Plain wording, no money anywhere — the
  # collections and plan revenue belong to the owner report only.
  class StaffFollowupPdf
    INK   = '1F2D3D'.freeze
    MUTED = '8A8F9A'.freeze
    ACCENT= 'FF5A1F'.freeze
    RULE  = 'DDE1E6'.freeze
    PANEL = 'F4F6F8'.freeze
    GREEN = '1E9E63'.freeze

    def initialize(data:, company: nil)
      @d = data
      @company = company
    end

    def render
      @pdf = Prawn::Document.new(page_size: 'A4', margin: [34, 38, 46, 38])
      @pdf.font 'Helvetica'

      masthead
      counters
      call_list
      machine_problems
      wrong_numbers
      footer_note
      page_footers
      @pdf.render
    end

    def filename
      "Spine-Fitness-Staff-List-#{@d[:period].to_s.tr(' ', '-')}.pdf"
    end

    private

    attr_reader :pdf

    def masthead
      pdf.fill_color INK
      pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 52
      pdf.fill_color 'FFFFFF'
      pdf.text_box 'SPINE FITNESS', at: [14, pdf.cursor - 12], width: 300, size: 14, style: :bold
      pdf.fill_color 'C8CAD0'
      pdf.text_box 'Monday list for gym staff', at: [14, pdf.cursor - 29], width: 300, size: 8
      pdf.fill_color ACCENT
      pdf.text_box 'WORK FOR THIS WEEK', at: [pdf.bounds.width - 250, pdf.cursor - 12],
                   width: 236, size: 12, style: :bold, align: :right
      pdf.fill_color 'FFFFFF'
      pdf.text_box @d[:period].to_s, at: [pdf.bounds.width - 250, pdf.cursor - 29],
                   width: 236, size: 9, align: :right
      pdf.move_down 66
      pdf.fill_color INK
    end

    def counters
      tiles = [
        ['Call these members', @d[:absent].size,         'did not come for 14 days'],
        ['No fingerprint',     @d[:no_fingerprint].size, 'cannot open the gate'],
        ['Finger not working', @d[:not_recorded].size,   'machine never saw them'],
        ['Wrong phone number', @d[:bad_numbers].size,    'our message did not reach']
      ]
      gap = 8
      width = (pdf.bounds.width - (gap * (tiles.size - 1))) / tiles.size
      top = pdf.cursor

      tiles.each_with_index do |(label, value, note), i|
        x = i * (width + gap)
        pdf.fill_color PANEL
        pdf.fill_rounded_rectangle [x, top], width, 56, 4
        pdf.fill_color ACCENT
        pdf.fill_rectangle [x, top], 3, 56
        pdf.fill_color MUTED
        pdf.text_box label.upcase, at: [x + 10, top - 10], width: width - 16, size: 6.6, style: :bold
        pdf.fill_color INK
        pdf.text_box value.to_s, at: [x + 10, top - 23], width: width - 16, size: 15, style: :bold
        pdf.fill_color MUTED
        pdf.text_box note, at: [x + 10, top - 42], width: width - 16, size: 6.6
      end
      pdf.move_down 72
      pdf.fill_color INK
    end

    def section(title, hint = nil)
      pdf.start_new_page if pdf.cursor < 70
      pdf.fill_color INK
      pdf.text title.upcase, size: 9.5, style: :bold, character_spacing: 0.9
      if hint
        pdf.fill_color MUTED
        pdf.text hint, size: 7.5
      end
      pdf.stroke_color RULE
      pdf.stroke_horizontal_rule
      pdf.move_down 8
      pdf.fill_color INK
    end

    def table(headers, rows, widths:, empty:)
      if rows.blank?
        pdf.fill_color GREEN
        pdf.text empty, size: 8.5, style: :italic
        pdf.fill_color INK
        pdf.move_down 12
        return
      end

      pdf.start_new_page if pdf.cursor < 90
      pdf.table([headers] + rows, width: pdf.bounds.width,
                cell_style: { border_width: 0, padding: [5, 7, 5, 7], size: 8.5 }) do |t|
        t.row(0).background_color = PANEL
        t.row(0).text_color = MUTED
        t.row(0).size = 7
        t.row(0).font_style = :bold
        t.rows(1..-1).borders = [:bottom]
        t.rows(1..-1).border_color = 'EEF1F4'
        widths.each_with_index { |w, i| t.column(i).width = pdf.bounds.width * w }
      end
      pdf.move_down 12
    end

    def call_list
      section('Call these members', 'They are paying, but they did not come for 14 days.')
      table(['Member', 'Phone', 'Last came', 'Days ago'],
            @d[:absent].map { |m| [m[:name], m[:phone].presence || 'no number',
                                   m[:last_seen]&.strftime('%d %b %Y').to_s, m[:days_ago].to_s] },
            widths: [0.36, 0.24, 0.24, 0.16],
            empty: 'Good. Everyone came in the last 14 days.')
    end

    def machine_problems
      section('Add fingerprint for these members',
              'They are paying, but the machine has no finger for them. ' \
              'They cannot open the gate. Someone has to let them in every time.')
      table(['Member', 'Phone', 'Paid till', 'Days left'],
            @d[:no_fingerprint].map { |m| [m[:name], m[:phone].presence || 'no number',
                                           m[:valid_till]&.strftime('%d %b %Y').to_s,
                                           m[:days_left].to_s] },
            widths: [0.34, 0.24, 0.24, 0.18],
            empty: 'Good. Every paying member has a fingerprint.')

      section('Fingerprint is not working',
              'Their finger is on the machine, but the machine has never seen them. ' \
              'Please scan the finger again.')
      table(['Member', 'Phone'],
            @d[:not_recorded].map { |m| [m[:name], m[:phone].presence || 'no number'] },
            widths: [0.6, 0.4],
            empty: 'Good. No problem.')
    end

    def wrong_numbers
      section('Fix these phone numbers',
              'Our WhatsApp did not reach them. The number is wrong. ' \
              'Please ask them and change it in the software.')
      table(['Member', 'Number we have', 'Failed', 'Last tried'],
            @d[:bad_numbers].map { |m| [m[:name], m[:phone].presence || 'no number',
                                        "#{m[:failures]} times", m[:last_try]&.strftime('%d %b %Y').to_s] },
            widths: [0.36, 0.24, 0.18, 0.22],
            empty: 'Good. All members are getting our messages.')
    end

    def footer_note
      pdf.move_down 4
      pdf.fill_color MUTED
      pdf.text 'This list has only members who are paying now. ' \
               'After you fix something, please change it in the software. ' \
               'Then next Monday the list will be correct.',
               size: 7.5
      pdf.fill_color INK
    end

    def page_footers
      pdf.repeat(:all, dynamic: true) do
        pdf.fill_color MUTED
        pdf.draw_text "Prepared #{@d[:generated_at]&.strftime('%d %b %Y, %l:%M %p')&.squeeze(' ')} · Spine Fitness",
                      at: [0, -16], size: 7
        pdf.draw_text "Page #{pdf.page_number}", at: [pdf.bounds.width - 40, -16], size: 7
        pdf.fill_color INK
      end
    end
  end
end
