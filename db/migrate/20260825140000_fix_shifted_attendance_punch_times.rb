class FixShiftedAttendancePunchTimes < ActiveRecord::Migration[7.1]
  # Some punches were stored with the scanner's LOCAL (IST) clock in a column
  # that is read back as UTC, so they displayed 5h30m late — evening sessions
  # showed up after midnight on the next day's report.
  #
  # Cause: both ingest paths used `Time.zone.parse`, and `Time.zone=` was being
  # assigned in a few controller helpers. That setter is thread-local and Puma
  # reuses threads, so the same device produced correct and shifted rows
  # depending on what had run on that thread earlier. Both paths now parse
  # explicitly in Asia/Kolkata and nothing assigns Time.zone any more.
  #
  # A row is identifiable because created_at is written by Rails in true UTC at
  # save time: a correct punch sits at or before it, a shifted one sits AHEAD
  # of it — impossible in reality, since a punch cannot happen after the row
  # recording it was written. The gap is 5h30m minus however long the bridge
  # took to post, so batched uploads land well under 330; the window starts at
  # an hour, comfortably above any plausible device/server clock skew.
  SHIFT_MINUTES = 330

  def up
    fixed = execute_fix(-SHIFT_MINUTES)
    say "Corrected #{affected_count_before} shifted punch rows" if fixed
  end

  def down
    # Put the shift back for anything this migration moved.
    execute <<~SQL
      UPDATE trn_member_attendances
      SET    att_punch_time = att_punch_time + INTERVAL #{SHIFT_MINUTES} MINUTE,
             att_punch_date = DATE(att_punch_time + INTERVAL #{SHIFT_MINUTES} MINUTE),
             updated_at     = NOW()
      WHERE  TIMESTAMPDIFF(MINUTE, created_at, att_punch_time) BETWEEN -30 AND 30
      AND    updated_at >= '#{Time.current.utc.strftime('%Y-%m-%d %H:%M:%S')}'
    SQL
  end

  private

  def affected_count_before
    @affected_count_before ||= select_value(<<~SQL).to_i
      SELECT COUNT(*) FROM trn_member_attendances
      WHERE TIMESTAMPDIFF(MINUTE, created_at, att_punch_time) BETWEEN 60 AND 360
    SQL
  end

  def execute_fix(delta)
    affected_count_before
    execute <<~SQL
      UPDATE trn_member_attendances
      SET    att_punch_time = att_punch_time + INTERVAL #{delta} MINUTE,
             att_punch_date = DATE(att_punch_time + INTERVAL #{delta} MINUTE),
             updated_at     = NOW()
      WHERE  TIMESTAMPDIFF(MINUTE, created_at, att_punch_time) BETWEEN 60 AND 360
    SQL
    true
  end
end
