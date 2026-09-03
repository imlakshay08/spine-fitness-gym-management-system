/*
 * Header notification bell.
 *
 * These are live conditions, not a message log — the server recomputes them on
 * every poll, so an item vanishes on its own once the thing it reports is
 * fixed. Nothing is marked as read here and nothing is stored client side.
 */
(function () {
  'use strict';

  var POLL_MS = 60000;
  var LEVEL_CLASS = {
    alert: 'deepPink-bgcolor',
    warn: 'yellow',
    info: 'blue-bgcolor'
  };
  var LEVEL_ICON = {
    alert: 'fa fa-warning',
    warn: 'fa fa-clock-o',
    info: 'fa fa-info'
  };

  function root() {
    var el = document.getElementById('globalrootaccess');
    return el && el.value ? el.value : '/';
  }

  function escapeHtml(text) {
    var div = document.createElement('div');
    div.appendChild(document.createTextNode(text == null ? '' : String(text)));
    return div.innerHTML;
  }

  function renderItem(item) {
    var tone = LEVEL_CLASS[item.level] || LEVEL_CLASS.info;
    var icon = LEVEL_ICON[item.level] || LEVEL_ICON.info;
    var href = root().replace(/\/$/, '') + (item.link || '/');

    return '' +
      '<li class="spine-notif-item spine-notif-' + escapeHtml(item.level) + '">' +
        '<a href="' + escapeHtml(href) + '">' +
          '<span class="details">' +
            '<span class="notification-icon circle ' + tone + '"><i class="' + icon + '"></i></span>' +
            '<b>' + escapeHtml(item.title) + '</b><br>' +
            '<small>' + escapeHtml(item.detail) + '</small>' +
          '</span>' +
        '</a>' +
      '</li>';
  }

  function paint(data) {
    var list = document.getElementById('spineNotifList');
    var badge = document.getElementById('spineNotifBadge');
    var summary = document.getElementById('spineNotifSummary');
    if (!list || !badge || !summary) { return; }

    var items = (data && data.items) || [];

    if (!items.length) {
      list.innerHTML = '<li class="spine-notif-empty"><a href="javascript:;">' +
        '<span class="details">Everything looks fine.</span></a></li>';
    } else {
      list.innerHTML = items.map(renderItem).join('');
    }

    var count = (data && data.badge) || 0;
    if (count > 0) {
      badge.textContent = count > 9 ? '9+' : String(count);
      badge.style.display = '';
    } else {
      badge.style.display = 'none';
    }

    if (data && data.error) {
      summary.textContent = 'Could not check';
    } else if (count > 0) {
      summary.textContent = 'Needs attention ' + count;
    } else {
      summary.textContent = 'All clear';
    }
  }

  function refresh() {
    if (document.hidden) { return; }

    var url = root().replace(/\/$/, '') + '/notifications';

    if (window.jQuery) {
      window.jQuery.getJSON(url).done(paint).fail(function () {
        paint({ items: [], badge: 0, error: true });
      });
      return;
    }

    fetch(url, { headers: { Accept: 'application/json' }, credentials: 'same-origin' })
      .then(function (r) { return r.json(); })
      .then(paint)
      .catch(function () { paint({ items: [], badge: 0, error: true }); });
  }

  document.addEventListener('DOMContentLoaded', function () {
    if (!document.getElementById('spineNotifList')) { return; }

    refresh();
    setInterval(refresh, POLL_MS);

    // Opening the bell should show current state, not whatever the last poll
    // happened to catch.
    var toggle = document.getElementById('spineNotifToggle');
    if (toggle) { toggle.addEventListener('click', refresh); }
  });
})();
