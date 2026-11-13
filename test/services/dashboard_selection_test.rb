require "test_helper"

module LesliDashboard
    class DashboardSelectionTest < ActiveSupport::TestCase
        setup do
            @accounts = 2.times.map do |index|
                core = Lesli::Account.create!(name: "Dashboard #{index}", email: "dashboard-#{index}@example.com", status: :active, region: :america)
                core.dashboard || core.create_dashboard!
            end
            @service = DashboardService.new(Struct.new(:account).new(@accounts.first.account))
            @first = @accounts.first.dashboards.create!(name: "First", engine: "Example", default: true)
            @second = @accounts.first.dashboards.create!(name: "Second", engine: "Example")
            @other_engine = @accounts.first.dashboards.create!(name: "Other", engine: "Other", default: true)
            @foreign = @accounts.last.dashboards.create!(name: "Foreign", engine: "Example", default: true)
        end

        test "selects the default by account and engine" do
            assert_equal @first, @service.show(engine: "Example").result
            assert_equal @other_engine, @service.show(engine: "Other").result
            assert_nil @service.show(engine: "Missing").result
        end

        test "selects a specific dashboard without falling back across scopes" do
            assert_equal @second, @service.show(engine: "Example", id: @second.id).result
            [@foreign.id, @other_engine.id, 0].each do |id|
                assert_raises(ActiveRecord::RecordNotFound) { @service.show(engine: "Example", id: id) }
            end
            @second.destroy!
            assert_raises(ActiveRecord::RecordNotFound) { @service.show(engine: "Example", id: @second.id) }
        end

        test "orders widgets by position and identifier and resolves their owner" do
            last = @first.components.create!(component: "chart_bar", position: 2, size: 4, config: {})
            first = @first.components.create!(component: "count", position: 1, size: 4, config: {})
            second = @first.components.create!(component: "count", position: 1, size: 4, config: {})
            assert_equal [first, second, last], @first.components.order(:position, :id).to_a
            presenter = DashboardPresenter.new(@first)
            assert_equal "example/dashboards/component-chart-bar", presenter.partial_path(last)
            assert_equal "md:col-span-6 lg:col-span-4", presenter.width_class(last)
            assert_empty @second.components
        end
    end
end
