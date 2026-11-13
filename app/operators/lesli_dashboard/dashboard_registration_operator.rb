module LesliDashboard
    class DashboardRegistrationOperator
        def initialize(account)
            @account = account
        end

        def operate
            # Keep the dashboard and all its initial components atomic. The workspace
            # lock also serializes repeated registrations for the same account.
            @account.with_lock do
                WidgetCatalog.engines.each do |engine|
                    # A deleted dashboard records a deliberate choice; registration
                    # must not resurrect it or restore widgets removed by the user.
                    next if @account.dashboards.with_deleted.exists?(engine: engine)

                    dashboard = @account.dashboards.create!(
                        engine: engine,
                        name: I18n.t("lesli_dashboard.dashboards.initial_name",
                            engine: engine.delete_prefix("Lesli")),
                        default: true
                    )
                    WidgetCatalog.widgets(engine).each do |widget|
                        dashboard.components.create!(
                            widget.options.deep_dup.merge(component: widget.identifier)
                        )
                    end
                end
            end
            @account
        end
    end
end
