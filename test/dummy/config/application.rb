require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Dummy
    class Application < Rails::Application
        config.root = File.expand_path("..", __dir__)
        config.load_defaults Rails::VERSION::STRING.to_f
        config.action_controller.include_all_helpers = false
        # The dummy app lives inside the engine, so explicitly include migrations
        # that the engines' host-path checks intentionally skip here.
        config.paths["db/migrate"] = [
            Lesli::Engine.root.join("db/migrate").to_s,
            LesliDashboard::Engine.root.join("db/migrate").to_s
        ]
    end
end
