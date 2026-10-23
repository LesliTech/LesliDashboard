require "test_helper"

module LesliDashboard
    class VersionTest < ActiveSupport::TestCase
        test "has a version number" do
            assert_predicate LesliDashboard::VERSION, :present?
        end

        test "has a build number" do
            assert_predicate LesliDashboard::BUILD, :present?
        end
    end
end
