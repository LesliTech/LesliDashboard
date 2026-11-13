require "test_helper"

module LesliDashboard
    class DashboardRegistrationTest < ActiveSupport::TestCase
        setup do
            @core = Lesli::Account.create!(name: "Registration", email: "registration@example.com", status: :active, region: :america)
            @account = @core.dashboard
            @providers = WidgetCatalog.instance_variable_get(:@providers).dup
            WidgetCatalog.register("CustomEngine") { [:count, { chart: { size: 8, config: { limit: 5 } } }] }
        end

        teardown do
            WidgetCatalog.instance_variable_set(:@providers, @providers)
        end

        test "creating a core account automatically provisions its dashboards and widgets" do
            core = Lesli::Account.create!(
                name: "SaaS signup", email: "signup@example.com", status: :active, region: :america
            )

            workspace = core.dashboard
            assert_not_nil workspace
            WidgetCatalog.engines.each do |engine|
                dashboard = workspace.dashboards.find_by!(engine: engine, default: true)
                assert_equal WidgetCatalog.widgets(engine).map(&:identifier),
                    dashboard.components.order(:id).pluck(:component)
            end
            assert_equal 2, workspace.dashboards.find_by!(engine: "CustomEngine").components.count
            assert_equal WidgetCatalog.engines.size, workspace.dashboards.count
        end

        test "failed dashboard provisioning rolls back the core account signup" do
            WidgetCatalog.register("CustomEngine") { [{ invalid: { size: 99 } }] }

            assert_no_difference(["Lesli::Account.count", "Account.count", "Dashboard.count", "Component.count"]) do
                assert_raises(ActiveRecord::RecordInvalid) do
                    Lesli::Account.create!(
                        name: "Failed signup", email: "failed-signup@example.com", status: :active, region: :america
                    )
                end
            end
        end

        test "custom catalog exposes translated names partials and defaults" do
            widget = WidgetCatalog.widgets("CustomEngine").last
            assert_equal "chart", widget.identifier
            assert_equal "Chart", widget.name
            assert_equal "custom_engine/dashboards/component-chart", widget.partial
            assert_equal({ size: 8, position: 2, config: { limit: 5 } }, widget.options)
            assert_empty WidgetCatalog.widgets("UnknownEngine")
        end

        test "widget metadata comes from the registered definition" do
            WidgetCatalog.register("CustomEngine") do
                [{ summary: { name_key: "lesli_dashboard.dashboards.empty", partial: "custom/cards/summary" } }]
            end
            I18n.with_locale(:en) do
                widget = WidgetCatalog.widgets("CustomEngine").first
                assert_equal "Empty dashboard", widget.name
                assert_equal "custom/cards/summary", widget.partial
            end
        end

        test "registration preserves changes and removed widgets on repeat" do
            operator = DashboardRegistrationOperator.new(@account)
            operator.operate
            dashboard = @account.dashboards.find_by!(engine: "CustomEngine")
            dashboard.update!(name: "My dashboard")
            dashboard.components.first.destroy!
            remaining = dashboard.components.first
            remaining.update!(size: 6, config: { limit: 20 })
            WidgetCatalog.register("CustomEngine") { [:count, :chart, :new_widget] }
            operator.operate
            assert_equal 1, @account.dashboards.where(engine: "CustomEngine").count
            assert_equal "My dashboard", dashboard.reload.name
            assert_equal [remaining.id], dashboard.components.pluck(:id)
            assert_equal 6, remaining.reload.size
            assert_equal({ "limit" => 20 }, remaining.config)
            assert_equal 3, WidgetCatalog.widgets("CustomEngine").size
        end

        test "a failed component rolls back dashboard registration" do
            WidgetCatalog.register("CustomEngine") { [:count, { invalid: { size: 99 } }] }
            assert_no_difference("Component.count") do
                assert_raises(ActiveRecord::RecordInvalid) { DashboardRegistrationOperator.new(@account).operate }
            end
            assert_not @account.dashboards.exists?(engine: "CustomEngine")
        end

        test "registration retains deliberate dashboard deletion" do
            operator = DashboardRegistrationOperator.new(@account)
            operator.operate
            @account.dashboards.find_by!(engine: "CustomEngine").destroy!
            operator.operate
            assert_not @account.dashboards.exists?(engine: "CustomEngine")
            assert_equal 1, @account.dashboards.with_deleted.where(engine: "CustomEngine").count
        end

        test "creating a workspace initializes an existing core account" do
            @account.dashboards.with_deleted.each { |dashboard| dashboard.components.where(dashboard_id: dashboard.id).delete_all }
            @account.dashboards.with_deleted.where(account_id: @account.id).delete_all!
            @account.delete
            require "rake"
            load LesliDashboard::Engine.root.join("lib/tasks/lesli_dashboard_tasks.rake") unless Rake::Task.task_defined?("lesli_dashboard:register")
            Rake::Task.define_task(:environment)
            2.times do
                output, = capture_io do
                    Rake::Task["lesli_dashboard:register"].reenable
                    Rake::Task["lesli_dashboard:register"].invoke
                end
                assert_includes output, "LesliDashboard: Dashboard registration completed."
            end
            workspace = Account.find_by!(account: @core)
            assert_equal 1, workspace.dashboards.where(engine: "CustomEngine").count
            assert workspace.dashboards.exists?(engine: "CustomEngine", default: true)
        end
    end
end
