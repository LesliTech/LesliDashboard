require "test_helper"

module LesliDashboard
    class ComponentEditorTest < ActionController::TestCase
        tests ComponentsController

        setup do
            @routes = LesliDashboard::Engine.routes
            @core = Lesli::Account.create!(name: "Editor", email: "editor@example.com", status: :active, region: :america)
            @other = Lesli::Account.create!(name: "Other", email: "editor-other@example.com", status: :active, region: :america)
            @dashboard = @core.dashboard.dashboards.find_by!(engine: "LesliDashboard")
            @user = Struct.new(:account, :allowed) do
                def has_privileges_for?(*); allowed; end
                def full_name; "Editor"; end
                def roles; []; end
                def effective_timezone; Time.find_zone!("UTC"); end
            end.new(@core, true)
            user = @user
            @controller.define_singleton_method(:current_user) { user }
            @controller.class.helper_method :current_user
            @controller.define_singleton_method(:authenticate_request) { true }
            @controller.define_singleton_method(:log_requests) { true }
            @controller.define_singleton_method(:log) { |*| true }
            @controller.define_singleton_method(:_layout) { |*| false }
        end

        test "renders catalog and configured fields with LesliView" do
            get :index, params: { dashboard_id: @dashboard.id }
            assert_response :success
            assert_select "select[name='component[component]'] option[value='calendar']"
            assert_select "select[name='component[config][week_starts_on]']"
            assert_select "textarea", count: 0
        end

        test "creates repeated widget instances and appends them" do
            previous_position = @dashboard.components.maximum(:position)
            2.times do
                post :create, params: { dashboard_id: @dashboard.id, component: { component: "date", position: 1, dashboard_id: @other.dashboard.dashboards.first.id } }, format: :json
                assert_response :created
            end
            records = @dashboard.components.order(:id).last(2)
            assert_equal [previous_position + 1, previous_position + 2], records.map(&:position)
            assert_not_equal records.first.id, records.last.id
        end

        test "updates only allowed widget options and width" do
            component = @dashboard.components.find_by!(component: "calendar")
            patch :update, params: { dashboard_id: @dashboard.id, id: component.id,
                component: { size: 8, position: 99, config: { week_starts_on: "monday", arbitrary: "ignored" } } }, format: :json
            assert_response :success
            assert_equal 8, component.reload.size
            assert_equal({ "week_starts_on" => "monday" }, component.config)
            assert_not_equal 99, component.position
        end

        test "Turbo updates only the edited widget and preserves invalid form values" do
            component = @dashboard.components.find_by!(component: "calendar")
            patch :update, params: { dashboard_id: @dashboard.id, id: component.id, component: { size: 8 } }, format: :turbo_stream
            assert_response :success
            assert_select "turbo-stream[target='dashboard-component-#{component.id}']"
            patch :update, params: { dashboard_id: @dashboard.id, id: component.id,
                component: { size: 99, config: { week_starts_on: "monday" } } }, format: :turbo_stream
            assert_response :unprocessable_content
            assert_select "option[selected][value='99']"
            assert_select "option[selected][value='monday']"
            assert_equal 8, component.reload.size
        end

        test "moves tied positions consistently and boundary moves are harmless" do
            @dashboard.components.update_all(position: 1)
            before = @dashboard.components.order(:position, :id).pluck(:id)
            patch :move, params: { dashboard_id: @dashboard.id, id: before[1], direction: "up" }, format: :json
            assert_response :success
            assert_equal [before[1], before[0]] + before.drop(2), @dashboard.components.order(:position, :id).pluck(:id)
            patch :move, params: { dashboard_id: @dashboard.id, id: before[1], direction: "up" }, format: :json
            assert_response :success
        end

        test "reordering rolls back all positions if a record cannot be saved" do
            records = @dashboard.components.order(:position, :id).to_a
            records.last.update_column(:size, 99)
            before = @dashboard.components.order(:id).pluck(:id, :position)
            patch :move, params: { dashboard_id: @dashboard.id, id: records[1].id, direction: "up" }, format: :json
            assert_response :unprocessable_content
            assert_equal before, @dashboard.components.order(:id).pluck(:id, :position)
        end

        test "rejects unknown widgets and invalid option values" do
            post :create, params: { dashboard_id: @dashboard.id, component: { component: "unknown" } }, format: :turbo_stream
            assert_response :unprocessable_content
            assert_select "turbo-stream[target='dashboard-component-form']"
            component = @dashboard.components.find_by!(component: "calendar")
            patch :update, params: { dashboard_id: @dashboard.id, id: component.id, component: { config: { week_starts_on: "invalid" } } }, format: :json
            assert_response :unprocessable_content
        end

        test "scopes parent and component lookups and excludes deleted dashboards" do
            foreign = @other.dashboard.dashboards.first
            get :index, params: { dashboard_id: foreign.id }, format: :json
            assert_response :not_found
            component = @dashboard.components.first
            delete :destroy, params: { dashboard_id: foreign.id, id: component.id }, format: :json
            assert_response :not_found
            @dashboard.destroy!
            get :index, params: { dashboard_id: @dashboard.id }, format: :json
            assert_response :not_found
        end

        test "removes only one instance and renders an empty state" do
            component = @dashboard.components.first
            @dashboard.components.where.not(id: component.id).destroy_all
            delete :destroy, params: { dashboard_id: @dashboard.id, id: component.id }, format: :turbo_stream
            assert_response :success
            assert_select "turbo-stream[target='dashboard-components-list']"
            assert_empty @dashboard.components
            assert Dashboard.exists?(@dashboard.id)
        end

        test "Turbo creation resets the add form and HTML redirects to the editor" do
            post :create, params: { dashboard_id: @dashboard.id, component: { component: "date" } }, format: :turbo_stream
            assert_response :created
            assert_select "turbo-stream[target='dashboard-components-list']"
            assert_select "turbo-stream[target='dashboard-component-form']"
            assert_select "#dashboard-component-form option[selected][value='date']", count: 0
            post :create, params: { dashboard_id: @dashboard.id, component: { component: "date" } }, format: :html
            assert_response :see_other
            assert_redirected_to managed_dashboard_components_path(@dashboard)
        end

        test "component IDs cannot be used through another dashboard in the same account" do
            second = @core.dashboard.dashboards.create!(name: "Other layout", engine: "LesliDashboard")
            patch :update, params: { dashboard_id: second.id, id: @dashboard.components.first.id, component: { size: 8 } }, format: :json
            assert_response :not_found
        end

        test "typed options are converted and invalid integers retain the submitted text" do
            providers = WidgetCatalog.instance_variable_get(:@providers).dup
            WidgetCatalog.register("LesliDashboard") do
                [{ date: { settings: { title: { type: :text }, limit: { type: :integer }, enabled: { type: :boolean } } } }]
            end
            component = @dashboard.components.find_by!(component: "date")
            patch :update, params: { dashboard_id: @dashboard.id, id: component.id,
                component: { config: { title: "My date", limit: "5", enabled: "false", ignored: "value" } } }, format: :json
            assert_response :success
            assert_equal({ "title" => "My date", "limit" => 5, "enabled" => false }, component.reload.config)
            patch :update, params: { dashboard_id: @dashboard.id, id: component.id,
                component: { config: { limit: "invalid" } } }, format: :html
            assert_response :unprocessable_content
            assert_select "input[name='component[config][limit]'][value='invalid']"
            assert_equal 5, component.reload.config["limit"]
        ensure
            WidgetCatalog.instance_variable_set(:@providers, providers)
        end

        test "Shield denies component changes without privileges" do
            skip "LesliShield is optional" unless defined?(LesliShield)
            @user.allowed = false
            post :create, params: { dashboard_id: @dashboard.id, component: { component: "date" } }, format: :json
            assert_response :forbidden
        end

        test "failed component creation preserves selection and does not append a record" do
            providers = WidgetCatalog.instance_variable_get(:@providers).dup
            WidgetCatalog.register("LesliDashboard") { [{ date: { size: 99 } }] }
            before = @dashboard.components.order(:id).pluck(:id, :position)
            post :create, params: { dashboard_id: @dashboard.id, component: { component: "date" } }, format: :turbo_stream
            assert_response :unprocessable_content
            assert_select "#dashboard-component-form option[selected][value='date']"
            assert_select "#dashboard-component-form [role='alert']"
            assert_equal before, @dashboard.components.order(:id).pluck(:id, :position)
        ensure
            WidgetCatalog.instance_variable_set(:@providers, providers)
        end
    end
end
