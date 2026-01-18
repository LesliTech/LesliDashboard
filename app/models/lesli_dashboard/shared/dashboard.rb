module LesliDashboard
    module Shared
        class Dashboard < ::Lesli::ApplicationLesliRecord
            self.table_name = "lesli_dashboard_dashboards"
            self.abstract_class = true

            belongs_to :user,     class_name: 'Lesli::User', optional: true
            belongs_to :account,  class_name: 'LesliDashboard::Account'
            has_many :components, class_name: 'LesliDashboard::Component'

            after_update :verify_default_dashboard
            after_create :verify_default_dashboard

            COMPONENTS = []

            private

            # @return [void]
            # @descriptions This is an after_updated and after_create method that validates that at any moment in time, there is only
            #     one default dashboard in the engine. If there is another default dashboard, it's *default* field is set to false
            #     before committing the changes
            # @example
            #     CloudFocus::Dasbhoard.where(default: false).first.update!(default: true)
            #     # This will automatically trigger this function and remove the *default* field from the old default dashboard
            def verify_default_dashboard
                if default
                    dashboards = self.class.where.not(id: id).where(account: account)
                    self.class.where.not(id: id).where(account: account).update_all(default: false)
                end
    
                unless self.class.where(account: account).find_by(default: true)
                    errors.add(:base, I18n.t("core.dashboards.messages_danger_default_dashboard_must_exist"))
                    raise ActiveRecord::Rollback
                end
            end

            # Build the Rails models and engine information for 
            # the current engine implementing the shared dashboards
            # Example: For the LesliAudit engine
            # {
            #     :module_name => "audit", 
            #     :module_name_full => "LesliAudit", 
            #     :module_model => "LesliAudit::Dashboard", 
            #     :module_model_component => "LesliAudit::Dashboard::Component"
            # }
            def self.dynamic_info

                module_info = self.name.split("::")

                module_name = module_info[0].sub("Lesli", "").downcase
                
                {
                    module_name: module_name,
                    module_name_full: module_info[0],
                    module_model: "#{ module_info[0] }::Dashboard".constantize,
                    module_model_component: "#{ module_info[0] }::Dashboard::Component".constantize
                }
            end
        end
    end
end
