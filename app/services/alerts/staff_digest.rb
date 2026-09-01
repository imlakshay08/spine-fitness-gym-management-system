module Alerts
  # The Monday list for the floor staff. Deliberately holds no money figures —
  # collections and plan revenue belong to the owner report only.
  #
  # "Has not come in 14 days" is split three ways, because lumping them together
  # would make more than half the list wrong: someone the machine has never
  # recorded has not necessarily stopped coming, and telling staff to phone them
  # about it wastes the call and their trust in the message.
  class StaffDigest < Reports::GymReportBase
    ABSENT_DAYS = 14

    def call
      {
        generated_at:  in_ist(Time.current),
        period:        today.strftime('%d %b %Y'),
        absent:        absent_members,
        not_recorded:  enrolled_but_unseen,
        not_enrolled:  never_enrolled,
        bad_numbers:   failing_numbers,
        active_total:  active_member_ids.size
      }
    end

    private

    # Every member with a running membership, and when the machine last saw them.
    def active_with_last_seen
      @active_with_last_seen ||= begin
        ids = active_member_ids
        return {} if ids.empty?

        last = TrnMemberAttendance
                 .where(att_compcode: compcode, att_status: 'ALLOWED', att_member_id: ids)
                 .group(:att_member_id)
                 .maximum(:att_punch_time)

        ids.index_with { |id| last[id] }
      end
    end

    def enrolled_ids
      @enrolled_ids ||= TrnMemberBiometricMapping
                          .where(mbm_compcode: compcode, mbm_is_active: 'Y')
                          .distinct.pluck(:mbm_member_id).map(&:to_s).to_set
    end

    # Known to the machine, but not seen for a fortnight — the real call list.
    def absent_members
      cutoff = today - ABSENT_DAYS

      active_with_last_seen
        .select { |id, seen| seen.present? && in_ist(seen).to_date <= cutoff && contactable?(id) }
        .map do |id, seen|
          seen_on = in_ist(seen).to_date
          { name: member_name(id), phone: member_phone(id),
            last_seen: seen_on, days_ago: (today - seen_on).to_i }
        end
        .sort_by { |m| -m[:days_ago] }
    end

    # Fingerprint is registered but no entry has ever been recorded — usually a
    # bad enrolment rather than a member who stopped coming.
    def enrolled_but_unseen
      active_with_last_seen
        .select { |id, seen| seen.blank? && enrolled_ids.include?(id.to_s) && contactable?(id) }
        .map { |id, _| { name: member_name(id), phone: member_phone(id) } }
        .sort_by { |m| m[:name].to_s }
    end

    # No fingerprint registered at all — they cannot get in on their own.
    def never_enrolled
      active_with_last_seen
        .select { |id, seen| seen.blank? && !enrolled_ids.include?(id.to_s) && contactable?(id) }
        .map { |id, _| { name: member_name(id), phone: member_phone(id) } }
        .sort_by { |m| m[:name].to_s }
    end

    # Messages that keep failing are nearly always a wrong phone number.
    def failing_numbers
      rows = TrnWhatsappLog
               .where(wl_compcode: compcode, wl_status: 'FAILED')
               .where('wl_sent_at >= ?', 60.days.ago)
               .to_a

      rows.group_by { |r| r.wl_member_id.to_s }
          .reject { |member_id, _| member_id.blank? }
          .map do |member_id, failures|
            { name:     member_name(member_id),
              phone:    member_phone(member_id),
              failures: failures.size,
              last_try: in_ist(failures.map(&:wl_sent_at).compact.max)&.to_date }
          end
          .select { |m| m[:name] != '(deleted member)' }
          .sort_by { |m| -m[:failures] }
    end
  end
end
