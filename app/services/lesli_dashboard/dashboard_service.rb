module LesliDashboard
    class DashboardService < Lesli::ApplicationLesliService

        DEFAULT_COMPONENT_OPTIONS = {
            size: 4,
            config: {},
            position: 1
        }.freeze

        def register account

            # Get all the installed and loaded engines 
            # to register a base dashboard for every engine
            LesliSystem.engines.each do |engine, data|

                # Skip not work module engine
                next if ['Lesli', 'LesliBabel', 'Root'].include?(engine)

                # Create a dashboard for the current engine
                dashboard = account.dashboards
                .create_with(:default => true)
                .find_or_create_by(engine: engine)

                # Get the components registered in every engine dashboard model
                "#{engine}::Dashboard".constantize::COMPONENTS.each do |component|

                    name, options =
                    case component
                        when Symbol
                            [component, {}]
                        when Hash
                            component.first
                        else
                            raise ArgumentError, "Invalid dashboard component: #{component.inspect}"
                    end

                    final_options = DEFAULT_COMPONENT_OPTIONS.merge(options || {})

                    dashboard.components
                        .create_with(final_options)
                        .find_or_create_by(component: name)
                end
            end
        end
    end
end
