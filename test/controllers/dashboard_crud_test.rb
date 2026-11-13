require "test_helper"

module LesliDashboard
    class DashboardCrudTest < ActionController::TestCase
        tests DashboardsController

        setup do
            @routes = LesliDashboard::Engine.routes
            @core = Lesli::Account.create!(name: "CRUD", email: "crud@example.com", status: :active, region: :america)
            @other = Lesli::Account.create!(name: "Other", email: "other-crud@example.com", status: :active, region: :america)
            @user = Struct.new(:account, :allowed) do
                def has_privileges_for?(*); allowed; end
                def full_name; "Test user"; end
                def roles; []; end
            end.new(@core, true)
            user = @user
            @controller.define_singleton_method(:current_user) { user }
            @controller.class.helper_method :current_user
            @controller.define_singleton_method(:authenticate_request) { true }
            @controller.define_singleton_method(:log_requests) { true }
            @controller.define_singleton_method(:log) { |*| true }
            @controller.define_singleton_method(:_layout) { |*| false }
        end

        test "navigation only includes dashboards from the same account and engine" do
            dashboard = @core.dashboard.dashboards.find_by!(engine: "LesliDashboard")
            sibling = dashboard.account.dashboards.create!(name: "Another view", engine: dashboard.engine)
            get :show, params: { id: dashboard.id }
            assert_response :success
            assert_select "nav[aria-label]" do
                assert_select "a", count: 2
                assert_select "a[href=?]", managed_dashboard_path(sibling)
                assert_select "span[aria-current='page']", count: 1
            end
        end

        test "engine entry points keep their route and offer creation when empty" do
            workspace = @core.dashboard
            dashboard = workspace.dashboards.find_by!(engine: "LesliDashboard")
            sibling = workspace.dashboards.create!(name: "Second", engine: dashboard.engine)
            get :show, params: { dashboard_id: sibling.id }
            assert_response :success
            assert_select "nav a[href=?]", "#{request.path}?dashboard_id=#{dashboard.id}"
            workspace.dashboards.where(engine: "LesliDashboard").each(&:destroy!)
            get :show
            assert_response :success
            assert_select "a[href=?]", new_managed_dashboard_path(engine: "LesliDashboard")
        end

        test "empty dashboards link to the widget editor and new forms preselect the engine" do
            dashboard = @core.dashboard.dashboards.create!(name: "Empty", engine: "LesliDashboard")
            get :show, params: { id: dashboard.id }
            assert_response :success
            assert_select "section[aria-label] a[href=?]", managed_dashboard_components_path(dashboard)
            get :new, params: { engine: "LesliDashboard" }
            assert_response :success
            assert_select "select[name='dashboard[engine]'] option[selected]", text: "LesliDashboard"
            get :new, params: { engine: "Unknown" }
            assert_response :success
            assert_select "select[name='dashboard[engine]'] option[value='Unknown']", count: 0
        end

        test "HTML lists scoped dashboards and renders forms" do
            get :index
            assert_response :success
            assert_select "table"
            assert_select "tbody tr:first-child td a[data-turbo-frame='_top']", count: 3
            assert_select "a[href=?][data-turbo-frame='_top']", new_managed_dashboard_path
            get :new
            assert_response :success
            assert_select "input[name='dashboard[name]']"
            assert_select "form[data-turbo-frame='_top']"
            dashboard = @core.dashboard.dashboards.first
            get :edit, params: { id: dashboard.id }
            assert_response :success
            assert_select "select[name='dashboard[engine]']", count: 0
        end

        test "JSON create ignores submitted account and update preserves engine" do
            post :create, params: { dashboard: { name: "My dashboard", engine: "LesliDashboard", account_id: @other.dashboard.id } }, format: :json
            assert_response :created
            dashboard = Dashboard.find(response.parsed_body.fetch("id"))
            assert_equal @core.dashboard, dashboard.account
            patch :update, params: { id: dashboard.id, dashboard: { name: "Renamed", engine: "LesliSupport", account_id: @other.dashboard.id } }, format: :json
            assert_response :success
            assert_equal "Renamed", dashboard.reload.name
            assert_equal "LesliDashboard", dashboard.engine
            assert_equal @core.dashboard, dashboard.account
            get :show, params: { id: dashboard.id }, format: :json
            assert_response :success
        end

        test "invalid engine and blank name return JSON and Turbo errors" do
            post :create, params: { dashboard: { name: "Invalid", engine: "Unknown" } }, format: :json
            assert_response :unprocessable_content
            assert response.parsed_body.fetch("errors").key?("engine")
            post :create, params: { dashboard: { name: "", engine: "LesliDashboard" } }, format: :turbo_stream
            assert_response :unprocessable_content
            assert_select 'turbo-stream[target="dashboard-form"]'
            assert_select "select[name='dashboard[engine]'] option[selected]", text: "LesliDashboard"
        end

        test "HTML and Turbo mutations redirect and deletion promotes replacement" do
            post :create, params: { dashboard: { name: "Replacement", engine: "LesliDashboard", default: true } }
            assert_response :see_other
            dashboard = @core.dashboard.dashboards.find_by!(name: "Replacement")
            patch :update, params: { id: dashboard.id, dashboard: { name: "Updated", default: true } }, format: :turbo_stream
            assert_response :see_other
            delete :destroy, params: { id: dashboard.id }, format: :turbo_stream
            assert_response :see_other
            assert_not Dashboard.exists?(dashboard.id)
            assert_equal 1, @core.dashboard.dashboards.where(engine: dashboard.engine, default: true).count
        end

        test "failed promotion leaves the previous default unchanged" do
            default = @core.dashboard.dashboards.find_by!(engine: "LesliDashboard", default: true)
            post :create, params: { dashboard: { name: "", engine: "LesliDashboard", default: true } }, format: :json
            assert_response :unprocessable_content
            assert default.reload.default?
            patch :update, params: { id: default.id, dashboard: { default: false } }, format: :json
            assert_response :unprocessable_content
            assert default.reload.default?
        end

        test "other accounts and missing dashboards return not found" do
            id = @other.dashboard.dashboards.first.id
            get :show, params: { id: id }, format: :json
            assert_response :not_found
            patch :update, params: { id: id, dashboard: { name: "Denied" } }, format: :json
            assert_response :not_found
            delete :destroy, params: { id: id }, format: :json
            assert_response :not_found
        end

        test "JSON index excludes other accounts and deletion allows an empty engine" do
            get :index, format: :json
            assert_response :success
            assert_equal @core.dashboard.dashboards.order(:engine, :name, :id).pluck(:id), response.parsed_body.map { |item| item.fetch("id") }
            dashboard = @core.dashboard.dashboards.find_by!(engine: "LesliDashboard")
            delete :destroy, params: { id: dashboard.id }, format: :json
            assert_response :success
            assert_empty @core.dashboard.dashboards.where(engine: "LesliDashboard")
        end

        test "failed HTML and Turbo updates preserve form values and the default" do
            dashboard = @core.dashboard.dashboards.find_by!(engine: "LesliDashboard", default: true)
            [:html, :turbo_stream].each do |format|
                patch :update, params: { id: dashboard.id, dashboard: { name: "My edited name", default: false } }, format: format
                assert_response :unprocessable_content
                assert_select "input[name='dashboard[name]'][value='My edited name']"
                assert dashboard.reload.default?
            end
        end

        test "management show renders widgets and legacy routes remain available" do
            dashboard = @core.dashboard.dashboards.find_by!(engine: "LesliDashboard")
            get :show, params: { id: dashboard.id }
            assert_response :success
            assert_select "article[data-dashboard-component]", count: dashboard.components.count
            assert_select "a[href=?][data-turbo-frame='_top']", managed_dashboards_path, minimum: 1
            assert_select "turbo-frame a[href=?][data-turbo-frame='_top']", managed_dashboards_path, count: 1
            assert_select "turbo-frame.lesli-application-container", count: 1
            assert_select "turbo-frame turbo-frame", count: 0
            assert_select "turbo-frame#dashboards-show [role='group']" do
                assert_select "a[href=?]", managed_dashboards_path
                assert_select "a[href=?]", edit_managed_dashboard_path(dashboard)
                assert_select "form[action=?] input[name='_method'][value='delete']", managed_dashboard_path(dashboard)
            end
            assert_recognizes({ controller: "lesli_dashboard/dashboards", action: "show" }, "/")
            assert_recognizes({ controller: "lesli_dashboard/dashboards", action: "show" }, "/dashboard")
            get :edit
            assert_response :success
        end

        test "management renders Admin widgets without its controller assigning a summary" do
            skip "LesliAdmin is optional" unless defined?(LesliAdmin)
            dashboard = @core.dashboard.dashboards.find_by!(engine: "LesliAdmin")
            get :show, params: { id: dashboard.id }
            assert_response :success
            %w[users roles installed_engines account_metadata].each do |widget|
                assert_select "article[data-dashboard-component=?]", widget, count: 1
            end
            assert_select "#account-metadata-title", text: "Account metadata"
            assert_select "article[data-dashboard-component='account_metadata'] dd", text: @core.id.to_s
        end

        test "Shield authorization denies mutations without privileges" do
            skip "LesliShield is optional" unless defined?(LesliShield)
            @user.allowed = false
            assert_no_difference("Dashboard.count") do
                post :create, params: { dashboard: { name: "Denied", engine: "LesliDashboard" } }, format: :json
            end
            assert_response :forbidden
        end
    end
end
