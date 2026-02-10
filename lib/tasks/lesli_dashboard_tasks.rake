namespace :lesli_dashboard do

    desc ""
    task :register => :environment do |task, args|
        dashboard_initialize()
    end

    # Drop, build, migrate & seed database (development only)
    def dashboard_initialize
        Lesli::Account.all.each do |account|
            LesliDashboard::DashboardService.new(nil).register(account.dashboard)
        end
        L2.msg("LesliDashboard: Dashboards initialized!")
    end
end
