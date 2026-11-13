require "test_helper"

module LesliDashboard
    class DashboardRenderingTest < ActiveSupport::TestCase
        class RenderingController < DashboardsController
            def current_user
                nil
            end
            helper_method :current_user
        end

        test "renders translated empty states through the Core dashboard entry point" do
            [nil, Dashboard.new(name: "Empty", engine: "LesliDashboard")].each do |dashboard|
                I18n.with_locale(:es) do
                    html = RenderingController.render(
                        template: "lesli/shared/dashboards/show",
                        layout: false,
                        assigns: { dashboard: dashboard, components: [], dashboard_presenter: DashboardPresenter.new(dashboard) }
                    )
                    document = Nokogiri::HTML.fragment(html)
                    assert document.at_css('section[aria-label="Panel vacío"]')
                    assert_includes document.text, "Panel vacío"
                end
            end
        end

        test "renders widgets through Core with translated accessibility text" do
            dashboard = Dashboard.new(engine: "LesliDashboard")
            component = Component.new(component: "date", size: 8)
            I18n.with_locale(:es) do
                html = RenderingController.render(
                    template: "lesli/shared/dashboards/show",
                    layout: false,
                    assigns: { dashboard: dashboard, components: [component], dashboard_presenter: DashboardPresenter.new(dashboard) }
                )
                document = Nokogiri::HTML.fragment(html)
                assert document.at_css('section[aria-label="Widgets del panel"]')
                assert_includes document.at_css('article')["class"], "lg:col-span-8"
            end
        end
    end
end
