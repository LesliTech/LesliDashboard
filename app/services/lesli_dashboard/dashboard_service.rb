module LesliDashboard
    class DashboardService < Lesli::ApplicationLesliService

        def show(engine:, id: nil)
            workspace = current_user.account.dashboard
            dashboards = workspace ? workspace.dashboards.where(engine: engine) : Dashboard.none
            response(id.nil? ? dashboards.find_by(default: true) : dashboards.find(id))
        end

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

    end
end
