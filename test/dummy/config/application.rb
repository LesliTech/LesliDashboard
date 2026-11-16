require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Dummy
    class Application < Rails::Application
        config.root = File.expand_path("..", __dir__)
        config.load_defaults Rails::VERSION::STRING.to_f
        config.action_controller.include_all_helpers = false
        # Include Core explicitly; Rails' engine test tasks add Dashboard's
        # own migrations. Adding them here too would register them twice.
        config.paths["db/migrate"] = [
            Lesli::Engine.root.join("db/migrate").to_s
        ]

        initializer :load_dashboard_test_migrations do |app|
            # Schema loading must record both Core and Dashboard migrations,
            # just as the dummy application's database tasks do.
            ActiveRecord::Migrator.migrations_paths = (
                app.paths["db/migrate"].expanded + LesliDashboard::Engine.paths["db/migrate"].expanded
            ).uniq
        end
    end
end
