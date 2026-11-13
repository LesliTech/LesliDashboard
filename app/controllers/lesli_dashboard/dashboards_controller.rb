=begin

Lesli

Copyright (c) 2026, Lesli Technologies, S. A.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see http://www.gnu.org/licenses/.

Lesli · Ruby on Rails SaaS Development Framework.

Made with ♥ by LesliTech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
=end
module LesliDashboard
    class DashboardsController < Lesli::Shared::DashboardsController
        helper_method :dashboard_action_allowed?

        before_action :load_dashboard, only: [:edit, :update, :destroy]

        def index
            @dashboards = DashboardService.new(current_user).index.result
            respond_with_lesli(json: @dashboards)
        end

        def show
            return super unless params[:id]

            @service = DashboardService.new(current_user).find(params[:id])
            return respond_with_not_found unless @service.found?

            @dashboard = @service.result
            @dashboard_engine = @dashboard.engine
            @dashboards = DashboardService.new(current_user).index(engine: @dashboard.engine).result
            @components = @dashboard.components.order(:position, :id)
            @dashboard_presenter = DashboardPresenter.new(@dashboard)
            respond_with_lesli(json: @dashboard)
        end

        def new
            engine = params[:engine] if WidgetCatalog.engines.include?(params[:engine])
            @dashboard = Dashboard.new(engine: engine)
        end

        def edit
        end

        def create
            @service = DashboardService.new(current_user).create(dashboard_params)
            @dashboard = @service.result
            return render_form(:new) unless @service.successful?

            success(t("lesli_dashboard.dashboards.created"))
            respond_with_lesli(json: @dashboard, status: :created, redirect: managed_dashboard_path(@dashboard))
        end

        def update
            @service.update(dashboard_params)
            @dashboard = @service.result
            return render_form(:edit) unless @service.successful?

            success(t("lesli_dashboard.dashboards.updated"))
            respond_with_lesli(json: @dashboard, redirect: managed_dashboard_path(@dashboard))
        end

        def destroy
            @service.destroy
            success(t("lesli_dashboard.dashboards.deleted"))
            respond_with_lesli(json: { id: @dashboard.id }, redirect: managed_dashboards_path)
        end

        private

        def dashboard_action_allowed?(action)
            !defined?(LesliShield) || current_user.has_privileges_for?("lesli_dashboard/dashboards", action)
        end

        def load_dashboard
            @service = DashboardService.new(current_user)
            # Preserve the existing singular edit URL for the engine's default.
            @service = if params[:id]
                @service.find(params[:id])
            else
                @service.show(engine: "LesliDashboard", id: params[:dashboard_id])
            end
            return respond_with_not_found unless @service.found?

            @dashboard = @service.result
        end

        def dashboard_params
            params.require(:dashboard).permit(:name, :engine, :default).to_h.symbolize_keys
        end

        def render_form(template)
            respond_with_lesli(
                html: template,
                json: { errors: @dashboard.errors.to_hash },
                turbo: turbo_stream.replace("dashboard-form", partial: "lesli_dashboard/dashboards/form"),
                status: :unprocessable_content
            )
        end
    end
end
