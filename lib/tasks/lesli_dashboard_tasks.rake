namespace :lesli_dashboard do

    desc ""
    task :initialize => :environment do |task, args|
        dashboard_initialize()
    end

    # Drop, build, migrate & seed database (development only)
    def dashboard_initialize
        engines = LesliSystem.engines

        engines.each do |engine_name, info|
            next if ["Root", "Lesli"].include?(engine_name)

            engine_account = "#{engine_name}::Account".constantize
            engine_dashboard = "#{engine_name}::Dashboard".constantize

            engine_account.all.each do |account|
                next unless account.respond_to?(:dashboards)
                engine_dashboard.initialize(account)
            end
        end

        L2.msg("LesliDashboard: Dashboards initialized!")
    end
end
