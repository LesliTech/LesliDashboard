require "test_helper"

module LesliDashboard
    class EngineTest < ActiveSupport::TestCase
        test "inherits from Rails engine" do
            assert LesliDashboard::Engine < Rails::Engine
        end

        test "isolates the LesliDashboard namespace" do
            assert_predicate LesliDashboard::Engine, :isolated?
        end

        test "defines its engine routes" do
            assert_predicate LesliDashboard::Engine.routes.routes, :any?
        end
    end
end
