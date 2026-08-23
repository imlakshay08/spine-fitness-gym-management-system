/* ------------------------------------------------------------------
   WhatsApp Inbox — Spine Fitness
   Live thread: polls for new messages, swaps conversations without a
   page reload, and keeps the transcript in true chronological order.
   ------------------------------------------------------------------ */
(function () {
  var shell = document.getElementById('waInbox');
  if (!shell) return;

  var POLL_MS   = 5000;
  var POLL_MAX  = 60000;   // back-off ceiling when the server is unhappy
  var TZ        = 'Asia/Kolkata';
  var BASE_TITLE = document.title;

  var el = {
    convList:  document.getElementById('waConvList'),
    messages:  document.getElementById('waMessages'),
    empty:     document.getElementById('waEmpty'),
    banner:    document.getElementById('waBanner'),
    jump:      document.getElementById('waJump'),
    jumpLabel: document.getElementById('waJumpLabel'),
    input:     document.getElementById('waInput'),
    send:      document.getElementById('waSend'),
    sendState: document.getElementById('waSendState'),
    search:    document.getElementById('waSearch'),
    filters:   shell.querySelectorAll('.wai-filters .wai-chip'),
    quick:     document.getElementById('waQuick'),
    name:      document.getElementById('waChatName'),
    phone:     document.getElementById('waChatPhone'),
    avatar:    document.getElementById('waChatAvatar'),
    context:   document.getElementById('waContext'),
    ctxToggle: document.getElementById('waCtxToggle'),
    back:      document.getElementById('waBack'),
    live:      document.getElementById('waLive'),
    unread:    document.getElementById('waUnreadCount')
  };

  var state = {
    base:    shell.dataset.base,
    token:   shell.dataset.token,
    number:  shell.dataset.number || '',
    cursor:  parseInt(shell.dataset.cursor || '0', 10),
    filter:  'all',
    query:   '',
    delay:   POLL_MS,
    timer:   null,
    busy:    false,
    sending: false,
    pending: 0,          // unseen arrivals while scrolled up
    convHtml: ''
  };

  /* ── helpers ────────────────────────────────────────────────────── */

  function istDay(date) {
    // en-CA gives YYYY-MM-DD, which matches what the server stamps on rows.
    return date.toLocaleDateString('en-CA', { timeZone: TZ });
  }

  function istClock(date) {
    return date.toLocaleTimeString('en-US', {
      timeZone: TZ, hour: 'numeric', minute: '2-digit'
    });
  }

  /* The shell fills whatever is left below the page bar. Measuring beats
     guessing a magic offset, and it survives theme padding changes. */
  function fitHeight() {
    var top    = shell.getBoundingClientRect().top;
    var footer = document.querySelector('.page-footer');
    var spare  = 22 + (footer ? footer.offsetHeight : 0);
    shell.style.height = Math.max(420, window.innerHeight - top - spare) + 'px';
  }

  function atBottom() {
    var m = el.messages;
    return (m.scrollHeight - m.scrollTop - m.clientHeight) < 90;
  }

  function scrollToBottom(smooth) {
    el.messages.scrollTo({ top: el.messages.scrollHeight, behavior: smooth ? 'smooth' : 'auto' });
  }

  /* Date separators are derived from the rows themselves, so they stay
     correct no matter how a row arrived — first paint, poll or send. */
  function refreshDividers() {
    var old = el.messages.querySelectorAll('.wai-day');
    for (var i = 0; i < old.length; i++) old[i].remove();

    var rows = el.messages.querySelectorAll('.wai-row');
    var seen = null;
    for (var j = 0; j < rows.length; j++) {
      var day = rows[j].dataset.day;
      if (day === seen) continue;
      seen = day;

      var divider = document.createElement('div');
      divider.className = 'wai-day';
      divider.innerHTML = '<span></span>';
      divider.firstChild.textContent = rows[j].dataset.dayLabel || day;
      el.messages.insertBefore(divider, rows[j]);
    }
  }

  function appendHtml(html) {
    if (!html) return [];

    var holder = document.createElement('div');
    holder.innerHTML = html;

    var added = [];
    var rows = holder.querySelectorAll('.wai-row');
    for (var i = 0; i < rows.length; i++) {
      // Move the cursor even for rows we already hold, so the next poll does
      // not keep re-sending them.
      var epoch = parseInt(rows[i].dataset.epoch || '0', 10);
      if (epoch > state.cursor) state.cursor = epoch;

      var key = rows[i].dataset.key;
      if (key && el.messages.querySelector('[data-key="' + key + '"]')) continue; // already here

      el.messages.appendChild(rows[i]);
      added.push(rows[i]);
    }
    return added;
  }

  function setTitleBadge(count) {
    document.title = count > 0 ? '(' + count + ') ' + BASE_TITLE : BASE_TITLE;
  }

  // A short chime, synthesised so the page needs no audio asset.
  function chime() {
    try {
      var Ctx = window.AudioContext || window.webkitAudioContext;
      if (!Ctx) return;
      var ctx = new Ctx();
      var osc = ctx.createOscillator();
      var gain = ctx.createGain();
      osc.connect(gain); gain.connect(ctx.destination);
      osc.type = 'sine';
      osc.frequency.setValueAtTime(880, ctx.currentTime);
      osc.frequency.setValueAtTime(1180, ctx.currentTime + 0.09);
      gain.gain.setValueAtTime(0.0001, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.09, ctx.currentTime + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.28);
      osc.start();
      osc.stop(ctx.currentTime + 0.3);
      setTimeout(function () { ctx.close(); }, 600);
    } catch (e) { /* audio is a nicety, never a blocker */ }
  }

  function request(path, options) {
    options = options || {};
    options.headers = Object.assign({
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-Token': state.token
    }, options.headers || {});
    options.credentials = 'same-origin';

    return fetch(state.base + path, options).then(function (res) {
      if (res.status === 401) throw new Error('session_expired');
      if (!res.ok) throw new Error('http_' + res.status);
      return res.json();
    });
  }

  /* ── conversation list ──────────────────────────────────────────── */

  function applyFilter() {
    var items = el.convList.querySelectorAll('.wai-conv');
    var shown = 0;

    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      var matchesText = !state.query || (item.dataset.search || '').indexOf(state.query) !== -1;
      var matchesTab  = state.filter === 'all' || parseInt(item.dataset.unread || '0', 10) > 0;
      var visible = matchesText && matchesTab;
      item.hidden = !visible;
      if (visible) shown++;
    }

    var blank = el.convList.querySelector('.wai-blank-search');
    if (blank) blank.hidden = shown > 0 || items.length === 0;
  }

  function paintConversations(html) {
    if (html === state.convHtml) return;   // nothing moved, keep the DOM still
    state.convHtml = html;
    el.convList.innerHTML = html;
    applyFilter();
  }

  function setUnread(total) {
    if (el.unread) el.unread.textContent = total;
    setTitleBadge(total);
  }

  /* ── opening a conversation ─────────────────────────────────────── */

  function openThread(number, push) {
    if (!number || state.busy) return;
    state.busy = true;
    shell.classList.add('is-loading');

    request('/thread?number=' + encodeURIComponent(number))
      .then(function (data) {
        state.number = data.number;
        state.cursor = data.cursor || 0;
        shell.dataset.number = data.number;
        shell.classList.remove('is-empty');

        el.name.textContent  = data.name;
        el.phone.textContent = data.phone;
        el.avatar.textContent = (data.initial || '?');
        el.avatar.className = 'wai-avatar wai-tone-' + (data.tone || 'a');

        el.messages.innerHTML = data.messages_html || '';
        refreshDividers();
        scrollToBottom(false);

        el.context.innerHTML = data.context_html || '';
        el.banner.hidden = !!data.session_open;
        el.input.disabled = false;
        el.send.disabled = false;
        el.sendState.textContent = '';

        paintConversations(data.conversations_html);
        setUnread(data.total_unread);
        clearPending();
        shell.classList.add('show-chat');

        if (push) {
          history.pushState({ number: data.number }, '',
            state.base + '?number=' + encodeURIComponent(data.number));
        }
      })
      .catch(handleError)
      .then(function () {
        state.busy = false;
        shell.classList.remove('is-loading');
      });
  }

  /* ── sending ────────────────────────────────────────────────────── */

  function tempBubble(text) {
    var now = new Date();
    var row = document.createElement('div');
    row.className = 'wai-row wai-row-out is-pending';
    row.dataset.key = 'tmp-' + now.getTime();
    row.dataset.epoch = Math.floor(now.getTime() / 1000);
    row.dataset.day = istDay(now);
    row.dataset.dayLabel = 'Today';
    row.innerHTML =
      '<div class="wai-bubble wai-bubble-staff">' +
        '<span class="wai-tag wai-tag-staff"><i class="fa-solid fa-headset"></i> You</span>' +
        '<p class="wai-text"></p>' +
        '<div class="wai-meta"><span class="wai-time"></span>' +
        '<span class="wai-tick-slot"><span class="wai-ticks is-sending">' +
        '<i class="fa-regular fa-clock"></i></span></span></div>' +
      '</div>';
    row.querySelector('.wai-text').textContent = text;
    row.querySelector('.wai-time').textContent = istClock(now);

    el.messages.appendChild(row);
    refreshDividers();
    scrollToBottom(true);
    return row;
  }

  function send() {
    var text = el.input.value.trim();
    if (!text || !state.number || state.sending) return;

    state.sending = true;
    el.send.disabled = true;
    el.input.value = '';
    autoGrow();

    var temp = tempBubble(text);
    el.sendState.textContent = 'Sending…';

    var body = new URLSearchParams();
    body.append('number', state.number);
    body.append('text', text);

    request('/reply', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
      body: body.toString()
    })
      .then(function (data) {
        temp.remove();
        appendHtml(data.html);
        refreshDividers();
        scrollToBottom(true);

        if (data.ok) {
          el.sendState.textContent = '';
        } else {
          el.sendState.innerHTML = '';
          el.sendState.textContent = data.error || 'Not delivered.';
          el.sendState.className = 'wai-send-error';
          el.input.value = text;          // hand the text back so it isn't lost
          autoGrow();
        }
      })
      .catch(function (err) {
        temp.querySelector('.wai-ticks').className = 'wai-ticks is-failed';
        temp.querySelector('.wai-ticks').innerHTML = '<i class="fa-solid fa-circle-exclamation"></i>';
        el.sendState.textContent = err.message === 'session_expired'
          ? 'Session expired — reload and sign in again.'
          : 'Could not reach the server.';
        el.sendState.className = 'wai-send-error';
        el.input.value = text;
        autoGrow();
        handleError(err);
      })
      .then(function () {
        state.sending = false;
        el.send.disabled = false;
        el.input.focus();
      });
  }

  /* ── polling ────────────────────────────────────────────────────── */

  function pending(count) {
    state.pending += count;
    if (state.pending > 0) {
      el.jumpLabel.textContent = state.pending + ' new message' + (state.pending > 1 ? 's' : '');
      el.jump.hidden = false;
    }
  }

  function clearPending() {
    state.pending = 0;
    el.jump.hidden = true;
  }

  function poll() {
    var query = '/poll?since=' + state.cursor +
                '&focused=' + (document.hasFocus() && !document.hidden ? '1' : '0');
    if (state.number) query += '&number=' + encodeURIComponent(state.number);

    request(query)
      .then(function (data) {
        state.delay = POLL_MS;
        el.live.classList.remove('is-down');

        paintConversations(data.conversations_html);
        setUnread(data.total_unread);

        // First conversation ever: open it instead of leaving a blank pane.
        if (!state.number) {
          var first = el.convList.querySelector('.wai-conv');
          if (first) openThread(first.dataset.number, true);
          return;
        }

        el.banner.hidden = !!data.session_open;

        var stick = atBottom();
        var added = appendHtml(data.messages_html);

        if (added.length) {
          refreshDividers();

          var inbound = added.filter(function (row) {
            return row.classList.contains('wai-row-in');
          }).length;

          if (stick) {
            scrollToBottom(true);
            clearPending();
          } else if (inbound) {
            pending(inbound);
          }

          if (inbound && (document.hidden || !document.hasFocus() || !stick)) chime();
        }

        // Ticks move after a bubble is already on screen.
        if (data.statuses) applyStatuses(data.statuses);
      })
      .catch(function (err) {
        el.live.classList.add('is-down');
        state.delay = Math.min(state.delay * 2, POLL_MAX);
        handleError(err);
      })
      .then(schedule);
  }

  function applyStatuses(map) {
    Object.keys(map).forEach(function (key) {
      var row = el.messages.querySelector('[data-key="' + key + '"]');
      if (!row) return;
      var slot = row.querySelector('.wai-tick-slot');
      if (!slot) return;

      var status = (map[key] || 'SENT').toUpperCase();
      if (slot.dataset.status === status) return;
      slot.dataset.status = status;

      var cls = 'is-sent', icon = 'fa-solid fa-check';
      if (status === 'READ')      { cls = 'is-read';      icon = 'fa-solid fa-check-double'; }
      else if (status === 'DELIVERED') { cls = 'is-delivered'; icon = 'fa-solid fa-check-double'; }
      else if (status === 'FAILED')    { cls = 'is-failed';    icon = 'fa-solid fa-circle-exclamation'; }

      slot.innerHTML = '<span class="wai-ticks ' + cls + '"><i class="' + icon + '"></i></span>';
      slot.title = status.charAt(0) + status.slice(1).toLowerCase();
    });
  }

  function schedule() {
    clearTimeout(state.timer);
    // No point hammering the server while the tab sits in the background.
    var wait = document.hidden ? Math.max(state.delay, 15000) : state.delay;
    state.timer = setTimeout(poll, wait);
  }

  function handleError(err) {
    if (err && err.message === 'session_expired') {
      clearTimeout(state.timer);
      el.live.classList.add('is-down');
      el.live.textContent = 'Signed out';
    }
  }

  /* ── composer sizing ────────────────────────────────────────────── */

  function autoGrow() {
    el.input.style.height = 'auto';
    el.input.style.height = Math.min(el.input.scrollHeight, 132) + 'px';
  }

  /* ── wiring ─────────────────────────────────────────────────────── */

  el.convList.addEventListener('click', function (e) {
    var link = e.target.closest('.wai-conv');
    if (!link) return;
    e.preventDefault();
    if (link.dataset.number === state.number) {
      shell.classList.add('show-chat');
      return;
    }
    openThread(link.dataset.number, true);
  });

  el.send.addEventListener('click', send);

  el.input.addEventListener('input', function () {
    autoGrow();
    if (el.sendState.className === 'wai-send-error') {
      el.sendState.className = '';
      el.sendState.textContent = '';
    }
  });

  el.input.addEventListener('keydown', function (e) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      send();
    }
  });

  el.messages.addEventListener('scroll', function () {
    if (atBottom()) clearPending();
  });

  el.jump.addEventListener('click', function () {
    scrollToBottom(true);
    clearPending();
  });

  el.search.addEventListener('input', function () {
    state.query = this.value.trim().toLowerCase();
    applyFilter();
  });

  Array.prototype.forEach.call(el.filters, function (chip) {
    chip.addEventListener('click', function () {
      Array.prototype.forEach.call(el.filters, function (c) { c.classList.remove('is-on'); });
      chip.classList.add('is-on');
      state.filter = chip.dataset.filter;
      applyFilter();
    });
  });

  el.quick.addEventListener('click', function (e) {
    var chip = e.target.closest('.wai-chip');
    if (!chip || el.input.disabled) return;
    el.input.value = chip.dataset.text;
    autoGrow();
    el.input.focus();
  });

  el.ctxToggle.addEventListener('click', function () {
    shell.classList.toggle('show-context');
  });

  el.back.addEventListener('click', function () {
    shell.classList.remove('show-chat');
  });

  window.addEventListener('popstate', function (e) {
    var number = (e.state && e.state.number) ||
                 new URLSearchParams(location.search).get('number');
    if (number) openThread(number, false);
  });

  document.addEventListener('visibilitychange', function () {
    if (!document.hidden) {
      state.delay = POLL_MS;
      clearTimeout(state.timer);
      poll();
    }
  });

  /* ── first paint ────────────────────────────────────────────────── */

  state.convHtml = el.convList.innerHTML;
  fitHeight();
  window.addEventListener('resize', fitHeight);
  window.addEventListener('load', function () {
    fitHeight();                                   // fonts/images can shift the page bar
    if (state.pending === 0) scrollToBottom(false);
  });
  refreshDividers();
  scrollToBottom(false);
  setUnread(parseInt(el.unread ? el.unread.textContent : '0', 10) || 0);
  if (state.number) {
    shell.classList.add('show-chat');
    el.input.focus();
  }
  autoGrow();
  schedule();
})();
