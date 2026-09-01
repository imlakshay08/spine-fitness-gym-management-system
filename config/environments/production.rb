Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Attempt to read encrypted secrets from `config/secrets.yml.enc`.
  # Requires an encryption key in `ENV["RAILS_MASTER_KEY"]` or
  # `config/secrets.yml.key`.
  config.read_encrypted_secrets = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=0, must-revalidate',
    'Pragma' => 'no-cache',
    'Expires' => '0'
  }
  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  #config.assets.js_compressor = :uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false
  config.assets.digest = false
  config.assets.enabled = false

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Redirect http:// to https://, and send HSTS so the browser refuses to
  # speak plain http to this host again.
  #
  # OFF by default, and deliberately so. Rails decides whether a request
  # arrived over https by reading X-Forwarded-Proto. Cloudflare sits in front
  # of this app, and if its SSL/TLS mode is "Flexible" it talks plain http to
  # the origin and sends X-Forwarded-Proto: http — Rails would then redirect
  # to https, Cloudflare would forward that as http again, and the app would
  # be stuck in a redirect loop for everyone.
  #
  # So: confirm Cloudflare SSL/TLS is "Full" or "Full (strict)" first, then
  # set FORCE_SSL=true. See SECURITY_FIXES.md.
  config.force_ssl = ENV['FORCE_SSL'].to_s.downcase == 'true'
  #
  # HSTS is a one-way door: once a browser sees it, it refuses plain http to
  # this host for the whole max-age and there is no way to call that back from
  # the server. subdomains is left OFF so it only ever covers the exact host
  # this app serves — turning it on would commit every future subdomain to
  # https too, for a year, whether or not it can do https.
  config.ssl_options = { hsts: { subdomains: false, preload: false, expires: 1.year } }

  # :debug logs every SQL statement with its bound values, so member names,
  # phone numbers and Aadhaar values were being written to the production log
  # on every page view. :info keeps request lines and app logging without the
  # data. LOG_LEVEL=debug when actually debugging something.
  config.log_level = ENV.fetch('LOG_LEVEL', 'info').to_sym

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "inventory_#{Rails.env}"
  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end
  # See the note in development.rb: no email is sent by this app. SMTP is only
  # configured if the environment supplies credentials.
  if ENV['SMTP_ADDRESS'].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      :address              => ENV['SMTP_ADDRESS'],
      :port                 => ENV.fetch('SMTP_PORT', 587).to_i,
      :user_name            => ENV['SMTP_USERNAME'],
      :password             => ENV['SMTP_PASSWORD'],
      :authentication       => "plain",
      :enable_starttls_auto => true
    }
  end
  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end
