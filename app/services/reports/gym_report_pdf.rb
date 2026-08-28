module Reports
  # Renders either owner report to a single, scannable PDF.
  #
  # Prawn 1.2.1 only has the built-in AFM fonts, which cannot encode the rupee
  # sign (it silently becomes "_"), so every amount arrives pre-formatted as
  # "Rs. ..." from the report services.
  class GymReportPdf
    INK     = '1F2D3D'.freeze
    MUTED   = '8A8F9A'.freeze
    ACCENT  = 'FF5A1F'.freeze
    RULE    = 'DDE1E6'.freeze
    PANEL   = 'F4F6F8'.freeze
    GREEN   = '1E9E63'.freeze
    RED     = 'C0392B'.freeze
    BLUE    = '2B6CB0'.freeze

    def initialize(data:, company: nil)
      @d       = data
      @company = company
    end

    def render
      @pdf = Prawn::Document.new(page_size: 'A4', margin: [34, 38, 46, 38])
      @pdf.font 'Helvetica'

      masthead
      kpi_row(@d[:kpis])

      if @d[:kind] == :daily
        daily_body
      else
        monthly_body
      end

      page_footers
      @pdf.render
    end

    def filename
      stamp = @d[:kind] == :daily ? Date.parse(@d[:period].split(', ').last).strftime('%d-%b-%Y') : @d[:period].tr(' ', '-')
      "Spine-Fitness-#{@d[:kind].to_s.capitalize}-Report-#{stamp}.pdf"
    rescue StandardError
      "Spine-Fitness-#{@d[:kind]}-report.pdf"
    end

    private

    attr_reader :pdf

    # ── chrome ──────────────────────────────────────────────────────────────

    def masthead
      pdf.fill_color INK
      pdf.fill_rectangle [0, pdf.cursor], pdf.bounds.width, 56

      pdf.fill_color 'FFFFFF'
      pdf.text_box 'SPINE FITNESS', at: [14, pdf.cursor - 12], width: 300, size: 15, style: :bold
      pdf.fill_color 'C8CAD0'
      pdf.text_box gym_line, at: [14, pdf.cursor - 30], width: 320, size: 7.5

      pdf.fill_color ACCENT
      pdf.text_box @d[:title], at: [pdf.bounds.width - 260, pdf.cursor - 12],
                   width: 246, size: 13, style: :bold, align: :right
      pdf.fill_color 'FFFFFF'
      pdf.text_box @d[:period], at: [pdf.bounds.width - 260, pdf.cursor - 31],
                   width: 246, size: 9.5, align: :right

      pdf.move_down 70
      pdf.fill_color INK
    end

    def gym_line
      [@company&.cmp_addressline1, @company&.cmp_addressline2].compact_blank.join(', ').presence ||
        'Dwarka, New Delhi'
    end

    def page_footers
      pdf.repeat(:all, dynamic: true) do
        pdf.fill_color MUTED
        pdf.draw_text "Generated #{@d[:generated_at]&.strftime('%d %b %Y, %l:%M %p')&.squeeze(' ')} · Spine Fitness ERP",
                      at: [0, -16], size: 7
        pdf.draw_text "Page #{pdf.page_number}", at: [pdf.bounds.width - 40, -16], size: 7
        pdf.fill_color INK
      end
    end

    # ── building blocks ─────────────────────────────────────────────────────

    def kpi_row(kpis)
      return if kpis.blank?

      gap   = 8
      width = (pdf.bounds.width - (gap * (kpis.size - 1))) / kpis.size
      top   = pdf.cursor

      kpis.each_with_index do |kpi, i|
        x = i * (width + gap)
        pdf.fill_color PANEL
        pdf.fill_rounded_rectangle [x, top], width, 58, 4

        pdf.fill_color ACCENT
        pdf.fill_rectangle [x, top], 3, 58

        pdf.fill_color MUTED
        pdf.text_box kpi[:label].to_s.upcase, at: [x + 11, top - 10], width: width - 18,
                     size: 6.8, style: :bold, character_spacing: 0.5
        pdf.fill_color INK
        pdf.text_box kpi[:value].to_s, at: [x + 11, top - 24], width: width - 18, size: 14, style: :bold
        pdf.fill_color MUTED
        pdf.text_box kpi[:note].to_s, at: [x + 11, top - 43], width: width - 18, size: 7
      end

      pdf.move_down 74
      pdf.fill_color INK
    end

    def section(title, hint = nil, tone: INK)
      keep(48)
      pdf.fill_color tone
      pdf.text title.upcase, size: 9.5, style: :bold, character_spacing: 0.9
      if hint
        pdf.fill_color MUTED
        pdf.text hint, size: 7.5
      end
      pdf.fill_color RULE
      pdf.stroke_color RULE
      pdf.stroke_horizontal_rule
      pdf.move_down 8
      pdf.fill_color INK
    end

    def table(headers, rows, widths: nil, aligns: {}, empty: 'Nothing to show')
      if rows.blank?
        pdf.fill_color MUTED
        pdf.text empty, size: 8.5, style: :italic
        pdf.fill_color INK
        pdf.move_down 12
        return
      end

      data = [headers] + rows
      keep([rows.size, 6].min * 18 + 40)

      pdf.table(data, width: pdf.bounds.width, cell_style: { border_width: 0, padding: [5, 7, 5, 7], size: 8.5 }) do |t|
        t.row(0).background_color = PANEL
        t.row(0).text_color       = MUTED
        t.row(0).size             = 7
        t.row(0).font_style       = :bold
        t.rows(1..-1).borders     = [:bottom]
        t.rows(1..-1).border_color = 'EEF1F4'
        aligns.each { |col, align| t.columns(col).align = align }
        widths&.each_with_index { |w, i| t.column(i).width = pdf.bounds.width * w }
      end
      pdf.move_down 12
    end

    def stat_line(pairs)
      keep(30)
      top = pdf.cursor
      col = pdf.bounds.width / pairs.size
      pairs.each_with_index do |(label, value), i|
        pdf.fill_color MUTED
        pdf.text_box label.to_s.upcase, at: [i * col, top], width: col - 6, size: 6.8, style: :bold
        pdf.fill_color INK
        pdf.text_box value.to_s, at: [i * col, top - 11], width: col - 6, size: 10, style: :bold
      end
      pdf.move_down 32
      pdf.fill_color INK
    end

    def callout(text, tone: ACCENT)
      keep(34)
      top = pdf.cursor
      pdf.fill_color PANEL
      pdf.fill_rounded_rectangle [0, top], pdf.bounds.width, 26, 3
      pdf.fill_color tone
      pdf.fill_rectangle [0, top], 3, 26
      pdf.fill_color INK
      pdf.text_box text, at: [11, top - 8], width: pdf.bounds.width - 20, size: 8.5
      pdf.move_down 34
    end

    # Simple horizontal bars — no chart library, just rectangles.
    def bars(rows, max_label: 22)
      return if rows.blank?
      peak = rows.map { |r| r[1].to_f }.max
      return if peak.zero?

      rows.each do |label, value|
        keep(16)
        top = pdf.cursor
        pdf.fill_color MUTED
        pdf.text_box label.to_s, at: [0, top], width: 96, size: 7.5
        bar_w = ((pdf.bounds.width - 150) * (value.to_f / peak)).round
        pdf.fill_color ACCENT
        pdf.fill_rounded_rectangle [100, top - 1], [bar_w, 3].max, 8, 2
        pdf.fill_color INK
        pdf.text_box value.to_s, at: [pdf.bounds.width - 40, top], width: 40, size: 7.5, align: :right
        pdf.move_down 13
      end
      pdf.move_down 6
      pdf.fill_color INK
    end

    def keep(space)
      pdf.start_new_page if pdf.cursor < space
    end

    def phone_or_dash(value)
      value.presence || '—'
    end

    # ── daily ───────────────────────────────────────────────────────────────

    def daily_body
      m = @d[:money]
      section('Money received today', "Total received so far this month: #{m[:mtd]}")
      stat_line([
        ['Received today',   m[:total_text]],
        ['Number of payments', m[:count].to_s],
        ['Yesterday',        m[:yesterday]],
        ['Compared to yesterday', m[:vs_yesterday].to_s]
      ])
      table(['Paid by', 'Amount', 'How many'],
            m[:by_mode].map { |x| [x[:mode], x[:amount_text], x[:count].to_s] },
            widths: [0.5, 0.3, 0.2], aligns: { 1 => :right, 2 => :right },
            empty: 'No money was received today.')

      section('Memberships taken today')
      table(['Member', 'New or renewed', 'Plan', 'Amount', 'Paid by', 'Valid till'],
            @d[:sales].map { |s| [s[:member], s[:type] == 'New' ? 'New member' : 'Renewed', s[:plan],
                                  s[:amount_text], s[:mode], s[:valid_to]&.strftime('%d %b %Y').to_s] },
            widths: [0.24, 0.15, 0.15, 0.15, 0.11, 0.20],
            aligns: { 3 => :right },
            empty: 'Nobody took or renewed a membership today.')

      who_came
      could_not_enter
      fees_due
      membership_footer
    end

    def who_came
      f = @d[:footfall]
      section('Members who came today',
              "#{f[:unique]} members came · busiest time #{f[:peak_label]} · "               "first at #{f[:first_label]}, last at #{f[:last_label]}")

      table(['Time', 'Member', 'Phone'],
            @d[:visitors].map { |v| [v[:at]&.strftime('%l:%M %p').to_s.strip, v[:name], phone_or_dash(v[:phone])] },
            widths: [0.18, 0.47, 0.35],
            empty: 'No member came to the gym today.')
    end

    def could_not_enter
      rows = @d[:turned_away]
      section('Members who could not enter')
      if rows.blank?
        callout('Everybody who came was allowed in.', tone: GREEN)
      else
        callout("#{rows.size} member#{'s' if rows.size != 1} came to the gym, but the machine did not "                 'let them in because their membership had already finished.', tone: RED)
        table(['Member', 'Phone', 'Came at', 'Membership finished'],
              rows.first(15).map { |r| [r[:name], phone_or_dash(r[:phone]),
                                        r[:at]&.strftime('%l:%M %p').to_s.strip,
                                        r[:expired_on] ? "#{r[:expired_on].strftime('%d %b %Y')} (#{r[:days_ago]} days ago)" : '—'] },
              widths: [0.28, 0.20, 0.16, 0.36])
      end
    end

    def fees_due
      a = @d[:attention]

      section('Memberships finishing in the next 7 days')
      table(['Member', 'Phone', 'Finishes on', 'Days left'],
            a[:expiring_7].first(15).map { |r| [r[:name], phone_or_dash(r[:phone]),
                                                r[:end_date]&.strftime('%d %b %Y').to_s,
                                                r[:days_left].zero? ? 'today' : r[:days_left].to_s] },
            widths: [0.36, 0.24, 0.24, 0.16], aligns: { 3 => :right },
            empty: 'No membership finishes in the next 7 days.')
      more_note(a[:expiring_7], 15)

      section('Memberships that finished recently and were not renewed')
      table(['Member', 'Phone', 'Finished on', 'How long ago'],
            a[:lapsed_45].first(15).map { |r| [r[:name], phone_or_dash(r[:phone]),
                                               r[:end_date]&.strftime('%d %b %Y').to_s,
                                               "#{r[:days_ago]} days"] },
            widths: [0.36, 0.24, 0.24, 0.16], aligns: { 3 => :right },
            empty: 'No membership finished in the last 45 days.')
      more_note(a[:lapsed_45], 15)

      section('Members who have not come for 2 weeks')
      table(['Member', 'Phone', 'Last came'],
            a[:quiet_14].first(12).map { |r| [r[:name], phone_or_dash(r[:phone]),
                                              r[:last_seen] ? r[:last_seen].strftime('%d %b %Y') : 'never'] },
            widths: [0.42, 0.28, 0.30],
            empty: 'Every member has come in the last 2 weeks.')
      more_note(a[:quiet_14], 12)
    end

    def more_note(list, shown)
      return if list.size <= shown
      pdf.fill_color MUTED
      pdf.text "#{list.size} in total, first #{shown} shown here.", size: 7.5, style: :italic
      pdf.fill_color INK
      pdf.move_down 10
    end

    def membership_footer
      m = @d[:membership]
      section('Total members')
      stat_line([
        ['Running memberships', m[:active].to_s],
        ['Members in the list', m[:on_roll].to_s],
        ['Joined today',        m[:joined_today].to_s],
        ['Finishing in 7 days', m[:expiring_7].to_s]
      ])
    end

    def hour_text(hour)
      display = hour % 12
      display = 12 if display.zero?
      "#{display} #{hour < 12 ? 'AM' : 'PM'}"
    end

    # ── monthly ─────────────────────────────────────────────────────────────

    def monthly_body
      m = @d[:money]
      section('Money received this month',
              m[:best_day] ? "Best day was #{m[:best_day].strftime('%d %b')} with #{m[:best_day_amount]}" : nil)
      change = m[:change_pct]
      stat_line([
        ['Received this month', m[:total_text]],
        ['Number of payments',  m[:count].to_s],
        ['Average payment',     m[:average]],
        ['Last month',          m[:previous]]
      ])
      if change
        callout("This month is #{change.abs}% #{change.positive? ? 'more' : 'less'} than last month "                 "(last month: #{m[:previous]}).", tone: change.positive? ? GREEN : RED)
      end
      table(['Paid by', 'Amount', 'How many'],
            m[:by_mode].map { |x| [x[:mode], x[:amount_text], x[:count].to_s] },
            widths: [0.5, 0.3, 0.2], aligns: { 1 => :right, 2 => :right },
            empty: 'No money was received this month.')

      section('Which plans members took')
      table(['Plan', 'How many took it', 'Money from this plan', 'Share'],
            @d[:plans].map { |p| [p[:plan], p[:count].to_s, p[:revenue_text], "#{p[:share]}%"] },
            widths: [0.34, 0.20, 0.28, 0.18], aligns: { 1 => :right, 2 => :right, 3 => :right },
            empty: 'Nobody took a membership this month.')

      g = @d[:growth]
      section('New and renewed members')
      stat_line([
        ['New members',      g[:new_members].to_s],
        ['Renewed',          g[:renewals].to_s],
        ['Money from new',   g[:new_revenue]],
        ['Money from renewals', g[:renewal_revenue]]
      ])
      if g[:due_to_expire].to_i.positive?
        callout("#{g[:due_to_expire]} memberships finished this month. "                 "#{g[:retained]} of them were renewed, #{g[:lost]} were not.",
                tone: g[:lost].to_i > g[:retained].to_i ? RED : GREEN)
      end

      section('Members whose membership finished and was not renewed')
      table(['Member', 'Phone'],
            g[:lost_members].map { |r| [r[:name], phone_or_dash(r[:phone])] },
            widths: [0.6, 0.4],
            empty: 'Everyone whose membership finished this month renewed it.')

      f = @d[:footfall]
      section('How many members came')
      stat_line([
        ['Total visits',       f[:visits].to_s],
        ['Different members',  f[:unique].to_s],
        ['Average per day',    f[:avg_per_day].to_s],
        ['Busiest time',       f[:busiest_hour].to_s]
      ])
      stat_line([
        ['Busiest day',   f[:busiest_day]&.strftime('%d %b').to_s],
        ['That day',      "#{f[:busiest_day_count]} members"],
        ['Busiest weekday', f[:busiest_weekday].to_s],
        ['Could not enter', "#{f[:denied]} times"]
      ])

      section('Members who came most often')
      table(['Member', 'Phone', 'Times they came'],
            @d[:regulars].map { |r| [r[:name], phone_or_dash(r[:phone]), r[:visits].to_s] },
            widths: [0.5, 0.3, 0.2], aligns: { 2 => :right },
            empty: 'Nobody came to the gym this month.')

      o = @d[:outlook]
      section('Memberships finishing next month')
      stat_line([
        ['Finishing next month', o[:expiring_count].to_s],
        ['Their total fees',     o[:at_risk]],
        ['Running memberships',  o[:active].to_s],
        ['Finished, not renewed', o[:lapsed_45].to_s]
      ])
      table(['Member', 'Phone', 'Finishes on'],
            o[:expiring].first(20).map { |r| [r[:name], phone_or_dash(r[:phone]),
                                              r[:end_date]&.strftime('%d %b %Y').to_s] },
            widths: [0.42, 0.28, 0.30],
            empty: 'No membership finishes next month.')
      more_note(o[:expiring], 20)
    end
  end
end
