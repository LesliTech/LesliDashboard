module LesliDashboard
    class DashboardService < Lesli::ApplicationLesliService

        def show(engine:, id: nil)
            workspace = current_user.account.dashboard
            dashboards = workspace ? workspace.dashboards.where(engine: engine) : Dashboard.none
            response(id.nil? ? dashboards.find_by(default: true) : dashboards.find(id))
        end

        DEFAULT_COMPONENT_OPTIONS = {
            size: 4,
            config: {},
            position: 1
        }.freeze

        # Lock the workspace so creation, promotion and deletion share one transaction.
        # The unique index additionally protects against writes outside this service.
        def create!(account:, engine:, name:, default: false)
            account.with_lock do
                dashboards = account.dashboards.where(engine: engine)
                make_default = default || !dashboards.exists?
                dashboards.update_all(default: false) if make_default
                dashboards.create!(name: name, default: make_default)
            end
        end

        def make_default!(dashboard)
            dashboard.account.with_lock do
                dashboard.reload
                dashboard.account.dashboards.where(engine: dashboard.engine)
                    .where.not(id: dashboard.id).update_all(default: false)
                dashboard.update!(default: true)
                dashboard
            end
        end

        def destroy!(dashboard)
            dashboard.account.with_lock do
                dashboard.reload
                was_default = dashboard.default?
                dashboard.update!(default: false)
                # Keep component records with their soft-deleted parent.
                dashboard.destroy!
                if was_default
                    replacement = dashboard.account.dashboards.where(engine: dashboard.engine)
                        .order(:created_at, :id).first
                    replacement&.update!(default: true)
                end
                dashboard
            end
        end

        def register account

            # Get all the installed and loaded engines 
            # to register a base dashboard for every engine
            LesliSystem.engines.each do |engine, data|

                # Skip not work module engine
                next if ['Lesli', 'LesliBabel', 'Root'].include?(engine)

                # Create a dashboard for the current engine
                dashboard = account.dashboards
                .find_by(engine: engine)
                dashboard ||= create!(account: account, engine: engine, name: "#{engine.delete_prefix('Lesli')} dashboard")

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
