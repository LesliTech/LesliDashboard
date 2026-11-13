module LesliDashboard
    class DashboardService < Lesli::ApplicationLesliService
        # Controller operations return this service: result holds the record or
        # collection, while successful? and errors describe validation failures.
        # Methods ending in ! return records directly and let exceptions propagate.

        # List active dashboards for the current account in a stable display order.
        def index(engine: nil)
            records = engine ? dashboards.where(engine: engine) : dashboards
            response(records.order(:engine, :name, :id))
        end

        # Store an account-scoped lookup for subsequent update/destroy operations.
        # A missing or inaccessible ID leaves result nil, so found? returns false.
        def find(id)
            response(dashboards.find_by(id: id))
        end

        # Create from submitted attributes using the authenticated user's workspace.
        # Account ownership is never taken from the submitted form.
        def create(attributes)
            dashboard = current_user.account.dashboard.dashboards.build(attributes.slice(:name, :engine, :default))
            dashboard.account.with_lock do
                # Only engines declared by server-side code may own new dashboards.
                unless WidgetCatalog.engines.include?(dashboard.engine)
                    dashboard.errors.add(:engine, :invalid)
                    raise ActiveRecord::RecordInvalid.new(dashboard)
                end
                siblings = dashboards.where(engine: dashboard.engine)
                # The first active dashboard is always the default. Clear an existing
                # default before saving its replacement to satisfy the unique index.
                dashboard.default = true unless siblings.exists?
                siblings.update_all(default: false) if dashboard.default?
                dashboard.save!
            end
            response(dashboard)
        rescue ActiveRecord::RecordInvalid => exception
            # The transaction restores the previous default; keep the invalid record
            # and its submitted values so the controller can render the form again.
            error(exception.record.errors.full_messages.to_sentence)
            response(exception.record)
        end

        # Update the record previously loaded with find. Restrict editable fields
        # so a dashboard cannot move to another account or engine.
        def update(attributes)
            dashboard = resource
            dashboard.account.with_lock do
                # Read the persisted default state after acquiring the workspace lock.
                dashboard.reload
                was_default = dashboard.default?
                dashboard.assign_attributes(attributes.slice(:name, :default))
                # Changing the default requires promoting another dashboard, rather
                # than leaving an engine with active dashboards but no default.
                if was_default && !dashboard.default?
                    dashboard.errors.add(:default, I18n.t("lesli_dashboard.dashboards.default_required"))
                    raise ActiveRecord::RecordInvalid.new(dashboard)
                end
                # Promotion and saving the edits must succeed or roll back together.
                if dashboard.default?
                    dashboards.where(engine: dashboard.engine).where.not(id: dashboard.id).update_all(default: false)
                end
                dashboard.save!
            end
            response(dashboard)
        rescue ActiveRecord::RecordInvalid => exception
            error(exception.record.errors.full_messages.to_sentence)
            response(exception.record)
        end

        # Delete the scoped record loaded with find, preserving the service contract.
        def destroy
            response(destroy!(resource))
        end

        # Resolve an engine's entry point within the current account. With no ID,
        # return its default or nil for the empty state. An explicit ID must match
        # both scopes; missing, deleted or inaccessible records raise RecordNotFound.
        def show(engine:, id: nil)
            workspace = current_user.account.dashboard
            dashboards = workspace ? workspace.dashboards.where(engine: engine) : Dashboard.none
            response(id.nil? ? dashboards.find_by(default: true) : dashboards.find(id))
        end

        # Explicit creation for trusted application code. The caller supplies the
        # workspace and engine; this method does not use the authenticated context
        # or validate catalog membership. Pass default as a boolean.
        # Workspace locking keeps creation and default changes in one transaction.
        # The unique index also prevents duplicate active defaults from other writers.
        def create!(account:, engine:, name:, default: false)
            account.with_lock do
                dashboards = account.dashboards.where(engine: engine)
                make_default = default || !dashboards.exists?
                dashboards.update_all(default: false) if make_default
                dashboards.create!(name: name, default: make_default)
            end
        end

        # Promote a trusted dashboard record within its own account and engine.
        # Callers must resolve access before passing a record to this operation.
        def make_default!(dashboard)
            dashboard.account.with_lock do
                dashboard.reload
                dashboard.account.dashboards.where(engine: dashboard.engine)
                    .where.not(id: dashboard.id).update_all(default: false)
                dashboard.update!(default: true)
                dashboard
            end
        end

        # Soft-delete a trusted dashboard record and replace its default atomically.
        # Callers must resolve access first, as this method uses the record's account.
        def destroy!(dashboard)
            dashboard.account.with_lock do
                dashboard.reload
                was_default = dashboard.default?
                dashboard.update!(default: false)
                # Keep component records with their soft-deleted parent.
                dashboard.destroy!
                if was_default
                    # Prefer the oldest remaining dashboard, with ID as a stable
                    # tie-breaker. Deleting the last dashboard leaves no replacement.
                    replacement = dashboard.account.dashboards.where(engine: dashboard.engine)
                        .order(:created_at, :id).first
                    replacement&.update!(default: true)
                end
                dashboard
            end
        end

        private

        # Shared account boundary for controller operations. The model's soft-delete
        # scope excludes deleted dashboards; a missing workspace is an empty relation.
        def dashboards
            workspace = current_user.account.dashboard
            workspace ? workspace.dashboards : Dashboard.none
        end
    end
end
