namespace :lesli_dashboard do
    desc "Initialize missing dashboards without changing existing layouts"
    task register: :environment do
        Lesli::Account.find_each do |core_account|
            account = LesliDashboard::Account.find_or_initialize_by(account: core_account)
            if account.persisted?
                LesliDashboard::DashboardRegistrationOperator.new(account).operate
            else
                # Creating the workspace initializes its dashboards through after_create.
                account.save!
            end
        end
        Termline.info("LesliDashboard: Dashboard registration completed.")
    end
end
