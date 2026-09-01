# Response headers that tell the browser to enforce a few things for us.
# Applied to every response; none of them change how the app behaves for staff.
Rails.application.config.action_dispatch.default_headers.merge!(
  # Never render the app inside someone else's <iframe>, which is what
  # clickjacking needs — an invisible frame over a page the victim thinks
  # they are clicking. Rails defaults to SAMEORIGIN; this is stricter.
  "X-Frame-Options"        => "DENY",

  # Stop the browser guessing a content type. An uploaded file that sniffs as
  # HTML cannot then be executed as a page.
  "X-Content-Type-Options" => "nosniff",

  # Do not leak the full URL (which carries member ids) to third-party sites
  # in the Referer header when staff click an outbound link.
  "Referrer-Policy"        => "strict-origin-when-cross-origin",

  # The app needs none of these device APIs; deny them outright.
  "Permissions-Policy"     => "camera=(), microphone=(), geolocation=(), payment=(), usb=()"
)

# Content-Security-Policy limits where scripts and styles may come from, which
# is the main thing that turns a stored-XSS into a non-event.
#
# The app loads Google Fonts, a Toastr stylesheet from cdnjs, and uses inline
# <script> and inline style attributes throughout, so 'unsafe-inline' has to
# stay for now — removing it means auditing every inline handler in the views.
# Even with that, this blocks loading executable script from any host that is
# not listed, which is what an injected <script src=…> needs.
#
# Report-only by default so nothing can break: violations are logged by the
# browser console, not enforced. Set CSP_ENFORCE=true once the console is
# clean on the pages staff actually use.
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.script_src  :self, :unsafe_inline, "https://cdnjs.cloudflare.com"
  policy.style_src   :self, :unsafe_inline, "https://fonts.googleapis.com", "https://cdnjs.cloudflare.com"
  policy.font_src    :self, :data, "https://fonts.gstatic.com", "https://cdnjs.cloudflare.com"
  policy.img_src     :self, :data, :https
  policy.connect_src :self
  # No plugins, and nobody may frame us (the modern form of X-Frame-Options).
  policy.object_src    :none
  policy.frame_ancestors :none
  policy.base_uri      :self
  # Never let a form on our page post credentials to another origin.
  policy.form_action   :self
end

Rails.application.config.content_security_policy_report_only =
  ENV['CSP_ENFORCE'].to_s.downcase != 'true'
