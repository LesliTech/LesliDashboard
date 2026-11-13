module LesliDashboard
    class ComponentsController < ApplicationController
        before_action :load_dashboard
        before_action :load_component, only: [:update, :destroy, :move]
        rescue_from ActiveRecord::RecordNotFound do
            respond_with_not_found
        end

        def index
            prepare_editor
            respond_with_lesli(json: @components)
        end

        def create
            @service.create(params.require(:component).permit(:component).to_h.symbolize_keys)
            respond_to_mutation(:created)
        end

        def update
            widget = @service.widgets.find { |definition| definition.identifier == @service.result.component }
            keys = widget ? widget.settings.keys : []
            attributes = params.require(:component).permit(:size, config: keys).to_h.symbolize_keys
            @service.update(attributes)
            respond_to_mutation(:updated)
        end

        def move
            @service.move(params.require(:direction))
            respond_to_mutation(:moved)
        end

        def destroy
            @service.destroy
            respond_to_mutation(:removed)
        end

        private

        def load_dashboard
            @service = ComponentService.new(current_user, dashboard_id: params[:dashboard_id])
            @dashboard = @service.dashboard
        end

        def load_component
            @service.find(params[:id])
        end

        def prepare_editor
            @widgets = @service.widgets.index_by(&:identifier)
            @components = @dashboard.components.order(:position, :id).to_a
            @new_component = @dashboard.components.build
        end

        def respond_to_mutation(message)
            component = @service.result
            prepare_editor
            if @service.successful?
                streams = if action_name == "update"
                    [turbo_stream.replace("dashboard-component-#{component.id}", partial: "lesli_dashboard/components/component", locals: { component: component })]
                else
                    [turbo_stream.replace("dashboard-components-list", partial: "lesli_dashboard/components/list")]
                end
                streams << turbo_stream.replace("dashboard-component-form", partial: "lesli_dashboard/components/form") if action_name == "create"
                streams << stream_notification_success(t("lesli_dashboard.components.#{message}"))
                respond_with_lesli(
                    turbo: streams, json: { component: component, components: @components },
                    redirect: managed_dashboard_components_path(@dashboard), status: action_name == "create" ? :created : :ok
                )
            else
                @new_component = component if action_name == "create"
                @components.map! { |record| record.id == component.id ? component : record }
                target = action_name == "create" ? "dashboard-component-form" : "dashboard-component-#{component.id}"
                partial = action_name == "create" ? "form" : "component"
                respond_with_lesli(
                    html: :index, status: :unprocessable_content,
                    json: { errors: component.errors.to_hash },
                    turbo: turbo_stream.replace(target, partial: "lesli_dashboard/components/#{partial}", locals: { component: component })
                )
            end
        end
    end
end
