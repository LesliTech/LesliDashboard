require "test_helper"

module LesliDashboard
    class DashboardConcurrencyTest < ActiveSupport::TestCase
        # Separate connections must see committed records to exercise real row locks.
        self.use_transactional_tests = false

        setup do
            skip "Row-lock concurrency is exercised on PostgreSQL; SQLite has one writer" unless ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            @core = Lesli::Account.create!(name: "Concurrency", email: "concurrency-#{SecureRandom.uuid}@example.com", status: :active, region: :america)
            @workspace = @core.dashboard
        end

        teardown do
            if @workspace
                dashboards = @workspace.dashboards.with_deleted
                Component.where(dashboard_id: dashboards.select(:id)).delete_all
                dashboards.delete_all!
                @workspace.delete
                @core.destroy!
            end
        end

        test "simultaneous registration creates only one dashboard per engine" do
            Component.where(dashboard_id: @workspace.dashboards.select(:id)).delete_all
            @workspace.dashboards.delete_all!
            concurrently do
                DashboardRegistrationOperator.new(Account.find(@workspace.id)).operate
            end
            WidgetCatalog.engines.each do |engine|
                records = @workspace.dashboards.where(engine: engine)
                assert_equal 1, records.count
                assert records.first.default?
                assert_equal WidgetCatalog.widgets(engine).size, records.first.components.count
            end
        end

        test "simultaneous promotions keep exactly one active default" do
            records = 2.times.map { |index| @workspace.dashboards.create!(name: "Concurrent #{index}", engine: "LesliDashboard") }
            concurrently do |index|
                DashboardService.new(nil).make_default!(Dashboard.find(records[index].id))
            end
            defaults = @workspace.dashboards.where(engine: "LesliDashboard", default: true)
            assert_equal 1, defaults.count
            assert_includes records.map(&:id), defaults.first.id
        end

        private

        def concurrently
            ready = Queue.new
            start = Queue.new
            threads = 2.times.map do |index|
                Thread.new do
                    ActiveRecord::Base.connection_pool.with_connection do
                        ready << true
                        start.pop
                        yield index
                    end
                end
            end
            2.times { ready.pop }
            2.times { start << true }
            # Thread#value propagates exceptions instead of hiding worker failures.
            threads.each(&:value)
        end
    end
end
