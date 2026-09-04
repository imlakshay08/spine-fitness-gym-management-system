module Notifications
  # What the bell in the header shows.
  #
  # These are live *conditions*, not a log of past events, and there is no
  # notifications table on purpose. A condition answers "what is wrong right
  # now", so it clears itself when the thing is fixed — the bridge coming back
  # online removes its own notification, with nothing to mark as read and no
  # row left behind. An event log would need write points scattered through the
  # app, a per-user read flag, and pruning, and it would still show yesterday's
  # outage as though it mattered.
  #
  # The one signal that genuinely is per-event — a member's WhatsApp reply —
  # already carries its own read state in `trn_whatsapp_inbox.wi_seen_at`.
  class Feed
    STALE_BRIDGE = 20.minutes

    # Two of these cost real time (ExpiryDigest loads every member, plan and
    # subscription), and the header renders on every page, so they are computed
    # at most once every few minutes and shared by everyone. Held in-process
    # rather than Rails.cache because production has no cache store configured.
    SLOW_TTL = 3.minutes

    CACHE      = {}
    CACHE_LOCK = Mutex.new

    def initialize(compcode: 'SF')
      @compcode = compcode
    end

    def call
      items = (quick_items + slow_items).compact

      {
        items:        items,
        badge:        items.count { |i| i[:badge] },
        generated_at: Time.current.in_time_zone('Asia/Kolkata').strftime('%l:%M %p').strip
      }
    end

    private

    attr_reader :compcode

    # ── the cheap ones: ~5 ms together, safe to run on every request ────────

    def quick_items
      [bridge_item, inbox_item, failed_item, dues_item]
    end

    def bridge_item
      beat      = TrnBridgeHeartbeat.where(bh_compcode: compcode).order(bh_last_seen: :desc).first
      last_seen = beat&.bh_last_seen
      return nil if last_seen.present? && last_seen > STALE_BRIDGE.ago

      detail =
        if last_seen.nil?
          'No signal has ever been received.'
        else
          "No signal since #{last_seen.in_time_zone('Asia/Kolkata').strftime('%l:%M %p').strip}."
        end

      item(:bridge, 'alert', 'wifi-off', 'Biometric machine is offline',
           "#{detail} Members cannot enter with their fingerprint.", '/', badge: true)
    end

    def inbox_item
      scope  = TrnWhatsappInbox.where(wi_compcode: compcode).unseen
      count  = scope.count
      return nil if count.zero?

      people = scope.distinct.count(:wi_from_number)

      item(:inbox, 'alert', 'message-circle',
           "#{count} unread #{'message'.pluralize(count)} on WhatsApp",
           "From #{people} #{'person'.pluralize(people)}. Nobody has opened #{count == 1 ? 'it' : 'them'} yet.",
           '/whatsapp_inbox', badge: true, count: count)
    end

    def failed_item
      count = TrnWhatsappLog
                .where(wl_compcode: compcode, wl_status: 'FAILED')
                .where('wl_sent_at >= ?', 7.days.ago)
                .count
      return nil if count.zero?

      item(:failed, 'alert', 'alert-triangle',
           "#{count} WhatsApp #{'message'.pluralize(count)} did not send",
           'Usually a wrong phone number. The member never got their reminder.',
           '/whatsapp_logs', badge: true, count: count)
    end

    def dues_item
      row   = TrnMemberSubscription.where(ms_compcode: compcode).where('ms_open_amount > 0')
      count = row.count
      return nil if count.zero?

      total = row.sum(:ms_open_amount).to_i

      # Deliberately not badged: this number moves slowly and is always
      # non-zero, so counting it would pin the badge at a figure that never
      # means "something happened today".
      item(:dues, 'info', 'indian-rupee',
           "#{count} #{'member'.pluralize(count)} still owe money",
           "Rs. #{ActiveSupport::NumberHelper.number_to_delimited(total)} outstanding in total.",
           '/member_subscriptions', badge: false, count: count)
    end

    # ── the expensive ones: cached ──────────────────────────────────────────

    def slow_items
      cached("slow:#{compcode}", SLOW_TTL) { build_slow_items }
    end

    def build_slow_items
      expiry = Alerts::ExpiryDigest.new(compcode: compcode).call
      staff  = Alerts::StaffDigest.new(compcode: compcode).call

      [
        expiring_item(expiry[:ending_today]),
        lapsed_item(expiry[:just_finished]),
        list_item(:no_fingerprint, staff[:no_fingerprint], 'user-x',
                  'are paying but have no fingerprint',
                  'They cannot open the gate — someone has to let them in every time.',
                  '/member_list'),
        list_item(:never_seen, staff[:not_recorded], 'help-circle',
                  'whose fingerprint has never worked',
                  'Registered on the machine, but no entry has ever been recorded.', '/member_list'),
        list_item(:bad_numbers, staff[:bad_numbers], 'phone-off',
                  'with a phone number that keeps failing',
                  'Messages to them bounce. The number needs correcting.', '/member_list'),
        list_item(:absent, staff[:absent], 'user-minus',
                  'have not come in 14 days',
                  'The Monday call list.', '/member_list')
      ].compact
    end

    def expiring_item(list)
      return nil if list.blank?

      item(:expiring_today, 'warn', 'clock',
           "#{list.size} #{'membership'.pluralize(list.size)} #{list.size == 1 ? 'finishes' : 'finish'} today",
           names(list) + ' — last day to catch them at the desk.',
           '/member_subscriptions', badge: true, count: list.size)
    end

    def lapsed_item(list)
      return nil if list.blank?

      item(:lapsed, 'warn', 'x-circle',
           "#{list.size} #{'membership'.pluralize(list.size)} finished yesterday",
           names(list) + ' — the gate will stop them now.',
           '/member_subscriptions', badge: true, count: list.size)
    end

    def list_item(key, list, icon, phrase, detail, link)
      return nil if list.blank?

      item(key, 'info', icon,
           "#{list.size} #{'member'.pluralize(list.size)} #{phrase}",
           detail, link, badge: false, count: list.size)
    end

    def names(list, limit = 3)
      shown = list.first(limit).map { |m| m[:name] }
      extra = list.size - shown.size

      extra.positive? ? "#{shown.join(', ')} and #{extra} more" : shown.join(', ')
    end

    # ── plumbing ────────────────────────────────────────────────────────────

    def item(key, level, icon, title, detail, link, badge: false, count: nil)
      { key: key, level: level, icon: icon, title: title,
        detail: detail, link: link, badge: badge, count: count }
    end

    # Computed outside the lock so a slow query never blocks other requests;
    # two threads racing just do the work twice, which is harmless.
    def cached(key, ttl)
      hit = CACHE_LOCK.synchronize do
        entry = CACHE[key]
        entry if entry && entry[:at] > ttl.ago
      end
      return hit[:value] if hit

      value = yield
      CACHE_LOCK.synchronize { CACHE[key] = { at: Time.current, value: value } }
      value
    end

    def self.clear_cache!
      CACHE_LOCK.synchronize { CACHE.clear }
    end
  end
end
