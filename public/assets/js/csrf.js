/**
 * Two jobs, both loaded immediately after jQuery on every page.
 *
 * 1. Attach the Rails CSRF token to every same-origin jQuery AJAX request.
 *    The app posts through $.ajax (often with FormData) rather than through
 *    submitted forms, so those requests carried no authenticity token and CSRF
 *    protection had to be switched off controller by controller. jQuery's
 *    beforeSend runs for every $.ajax call including ones made by plugins, so
 *    nothing needs changing call by call.
 *
 * 2. Own the alertChecked() delete handler.
 *    Deletes used to be a plain GET navigation, which anything that fetches a
 *    URL on the admin's behalf could fire — a link prefetcher, a "preload
 *    pages" browser setting, an email link scanner. The routes are DELETE-only
 *    now, so the handler has to submit a real form.
 *
 *    The per-page bundles each carry their own copy of alertChecked, and those
 *    are served through a CDN that may still be handing out the old cached
 *    version for a while after a deploy. A stale copy would do the old GET and
 *    hit a dead route. So the safe version is reinstalled on DOMContentLoaded,
 *    which runs after every one of those scripts has been parsed — whichever
 *    copy the CDN serves, this one wins.
 */
(function () {
  function csrfToken() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute('content') : null;
  }

  /* --- 1. CSRF token on every same-origin $.ajax call ------------------- */
  if (window.jQuery) {
    jQuery.ajaxSetup({
      beforeSend: function (xhr, settings) {
        // Never leak our token to another origin.
        if (settings.crossDomain) return;
        var t = csrfToken();
        if (t) xhr.setRequestHeader('X-CSRF-Token', t);
      }
    });
  }

  /* --- 2. Deletes go out as a real DELETE, not a GET navigation --------- */
  function safeDelete(url) {
    if (!confirm("Are you sure want to delete ?")) return;

    var form = document.createElement("form");
    form.method = "post";
    form.action = url;
    form.style.display = "none";

    var m = document.createElement("input");
    m.type = "hidden"; m.name = "_method"; m.value = "delete";
    form.appendChild(m);

    var t = csrfToken();
    if (t) {
      var f = document.createElement("input");
      f.type = "hidden"; f.name = "authenticity_token"; f.value = t;
      form.appendChild(f);
    }

    document.body.appendChild(form);
    form.submit();
  }

  window.alertChecked = safeDelete;

  // Page bundles define their own alertChecked when they are parsed, which is
  // before this fires. Reinstalling here makes ours the one that runs, even if
  // the CDN is still serving a pre-deploy copy of one of those bundles.
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", function () {
      window.alertChecked = safeDelete;
    });
  } else {
    window.alertChecked = safeDelete;
  }
})();
