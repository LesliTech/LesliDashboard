require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Dummy
    class Application < Rails::Application
        config.root = File.expand_path("..", __dir__)
        config.load_defaults Rails::VERSION::STRING.to_f
        config.action_controller.include_all_helpers = false
    end
end
