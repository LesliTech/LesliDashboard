ENV["RAILS_ENV"] ||= "test"

require "lesli_testing"

LesliTesting.engine("LesliDashboard", {
    coverage_min_coverage: 0.5,
    fixtures: false
})

require_relative "dummy/config/environment"
require "rails/test_help"
