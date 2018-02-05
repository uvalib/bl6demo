require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Bl6demo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.action_controller.permit_all_parameters = true # TODO: testing
    config.action_controller.action_on_unpermitted_parameters = :log
    config.action_controller.always_permitted_parameters = [
      # Rails
      'controller',
      'action',
      # Simple search
      'q',
      'f',
      'f[format][]',
      # Advanced search
      'f_inclusive',
      'f_inclusive[format][]',
      # Other
      'sort',
      'per_page',
    ]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
