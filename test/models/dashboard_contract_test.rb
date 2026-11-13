require "test_helper"

module LesliDashboard
    class DashboardContractTest < ActiveSupport::TestCase
        test "dashboard requires a name and engine" do
            dashboard = Dashboard.new(name: "  ")
            dashboard.validate
            assert dashboard.errors.added?(:name, :blank)
            assert dashboard.errors.added?(:engine, :blank)
        end

        test "component rejects invalid layout and configuration" do
            component = Component.new(component: "", size: 13, position: 0, config: [])
            component.validate
            [:component, :size, :position, :config].each do |attribute|
                assert component.errors[attribute].present?
            end
        end

        test "components have independent configuration defaults" do
            first = Component.new
            second = Component.new
            first.config["limit"] = 5
            assert_equal({}, second.config)
            assert_equal 4, second.size
            assert_equal 1, second.position
        end

        test "users belong to the core account through the workspace" do
            assert_equal :account, Account.reflect_on_association(:users).options[:through]
            assert_equal "lesli_dashboard_dashboards", Dashboard.table_name
            assert_equal "lesli_dashboard_components", Component.table_name
        end
    end
end
