require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)

module Ihm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Autoload lib folder
    config.autoload_paths += %W(#{config.root}/lib)

    # ActiveJob backend (important)
    config.active_job.queue_adapter = :async
  end
end
