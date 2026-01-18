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

            def self.initialize_account(account)

                pp "Initializing..."
                pp "Initializing..."
                pp "Initializing..."

                LesliSystem.engines.each do |engine, data|
                    next if ['Lesli', 'LesliBabel', 'Root'].include?(engine)
                    dashboard = account.dashboards
                    .create_with(:default => true)
                    .find_or_create_by(engine: engine)

                    #pp LesliSystem::Klass.new(engine: engine)
                    "#{engine}::Dashboard".constantize::COMPONENTS.each do |component|
                        dashboard.components.create_with(
                            :position => 1,
                            :size => 4
                        ).find_or_create_by(:component => component)
                    end
                end

                # dashboard = account.account.dashboards.dashboards
                # .create_with(:default => true)
                # .find_or_create_by(engine: klass.engine_name)

                # self::COMPONENTS.each do |component|
                #     dashboard.components.create(
                #         :component => component,
                #         :position => 1,
                #         :size => 4
                #     )
                # end

                pp "Finalizing..."
                pp "Finalizing..."
                pp "Finalizing..."
            end

            # @return [Hash] Hash of containing the information of the dashboard and its components.
            # @description Returns a hash with information about the dashboard and all its *components*.
            #     Each component is returned in the configuration view, not the render view. This means that
            #     this method is ment to be used when updating the dashboard
            # @example
            #     respond_with_successful(CloudHelp::Dashboard.first.show)
            def show
                attributes.merge({
                    components: components.order(index: :asc)
                    # components: [{
                    #     name: "ticket",
                    #     component_id: "ticket"
                    # },{
                    #     name: "ticket",
                    #     component_id: "ticket"
                    # }]
                })
            end

            # @return [Hash] Hash containing the options to create and manage dashboards
            # @param current_user [User] The user that made this request
            # @param query [Hash] Query containing filters. Currently unused, but required
            # @descriptions Returns a list of options needed to create and manage dashboard components. For now,
            #     the returned options are: A list of roles, the enoun containing the component_ids, generic configuration options
            #     for all dashboad components and a descriptions hash, that contains brief descriptions for each component to help
            #     the user understand what each component does. Any class that inherits from this one can send a block to add extra
            #     functionality. For example, the descriptions must be implemented directly from the engine.
            # @example
            #         CloudHouse::Dashboard.options(User.find(2), nil)
            def self.options(current_user, query)
                dynamic_info = self.dynamic_info
                component_model = dynamic_info[:module_model_component]

                component_ids = component_model.component_ids.map do |comp|
                    {
                        value: comp,
                        text: comp
                    }
                end

                options = {
                    component_ids: component_ids,
                    #components_configuration_options: component_model.configuration_options,
                    descriptions: {}
                }

                if block_given?
                    yield(options)
                else
                    return options
                end
            end

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
