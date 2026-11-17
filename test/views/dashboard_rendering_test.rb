require "test_helper"

module LesliDashboard
    class DashboardRenderingTest < ActiveSupport::TestCase
        class RenderingController < DashboardsController
            def current_user
                nil
            end
            helper_method :current_user

            helper do
                def lesli_engine(property = nil)
                    @rendering_engine || "lesli_dashboard"
                end
            end
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
            %w[lesli_dashboard lesli].each do |engine|
              I18n.with_locale(:es) do
                html = RenderingController.render(
                    inline: <<~ERB,
                        <% dashboard_html = render(template: "lesli/shared/dashboards/show") %>
                        <html>
                            <head>
                                <%= render "lesli/partials/application-lesli-assets" %>
                                <%= content_for(:head) if content_for?(:head) %>
                            </head>
                            <body><%= dashboard_html %></body>
                        </html>
                    ERB
                    layout: false,
                    assigns: {
                        lesli: {}, rendering_engine: engine,
                        dashboard: dashboard, components: [component],
                        dashboard_presenter: DashboardPresenter.new(dashboard)
                    }
                )
                document = Nokogiri::HTML(html)
                assert document.at_css('section[aria-label="Widgets del panel"]')
                styles = document.css('head link[rel="stylesheet"][href*="lesli_dashboard/application"]')
                assert_equal 1, styles.size
                assert_equal "dynamic", styles.first["data-turbo-track"] if engine == "lesli"
                assert_nil document.at_css('body link[rel="stylesheet"]')
                assert_includes document.at_css('article')["class"], "lg:col-span-8"
              end
            end
        end

        test "editor and navigation labels exist in every supported locale" do
            # Read the engine catalog independently: a host may load only a subset.
            previous_locales = I18n.available_locales
            I18n.available_locales = previous_locales | %i[en es fr it pt]
            translations = I18n::Backend::Simple.new
            translations.load_translations(*LesliDashboard::Engine.root.glob("config/locales/translations.*.yml"))
            %i[en es fr it pt].each do |locale|
                %w[dashboards.navigation dashboards.empty dashboards.new components.empty components.add components.created components.updated components.removed].each do |key|
                    assert translations.translate(locale, "lesli_dashboard.#{key}").present?
                end
            end
        ensure
            I18n.available_locales = previous_locales
        end
    end
end
