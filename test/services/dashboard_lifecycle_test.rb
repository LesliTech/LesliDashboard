require "test_helper"

module LesliDashboard
    class DashboardLifecycleTest < ActiveSupport::TestCase
        test "two accounts independently customize and replace defaults across engines" do
            accounts = 2.times.map do |index|
                Lesli::Account.create!(name: "Lifecycle #{index}", email: "lifecycle-#{index}@example.com", status: :active, region: :america)
            end
            layouts = accounts.flat_map do |core|
                service = DashboardService.new(Struct.new(:account).new(core))
                %w[Example Reports].map do |engine|
                    first = service.create!(account: core.dashboard, engine: engine, name: "First")
                    second = service.create!(account: core.dashboard, engine: engine, name: "Second")
                    [core, engine, first, second]
                end
            end
            layouts.each do |core, engine, first, second|
                service = DashboardService.new(Struct.new(:account).new(core))
                unaffected = Dashboard.where.not(id: [first.id, second.id])
                defaults_before = unaffected.order(:id).pluck(:id, :default)
                assert first.default?
                assert_not second.default?
                widget = second.components.create!(component: "date", size: 12, config: { title: core.name })
                service.make_default!(second)
                assert_not first.reload.default?
                assert second.reload.default?
                DashboardRegistrationOperator.new(core.dashboard).operate
                assert_equal second, service.show(engine: engine).result
                assert_equal({ "title" => core.name }, widget.reload.config)
                service.destroy!(second)
                assert first.reload.default?
                assert Component.exists?(widget.id), "Soft deletion retains components"
                service.destroy!(first)
                assert_nil service.show(engine: engine).result
                assert_equal defaults_before, unaffected.order(:id).pluck(:id, :default)
            end
        end

        test "database rejects a second active default even without model validation" do
            core = Lesli::Account.create!(name: "Constraint", email: "constraint@example.com", status: :active, region: :america)
            original = core.dashboard.dashboards.find_by!(engine: "LesliDashboard", default: true)
            other = core.dashboard.dashboards.create!(engine: original.engine, name: "Other")
            # Use a savepoint so PostgreSQL can continue after the expected violation.
            assert_raises(ActiveRecord::RecordNotUnique) do
                Dashboard.transaction(requires_new: true) { other.update_column(:default, true) }
            end
            assert original.reload.default?
            assert_not other.reload.default?
        end
    end
end
