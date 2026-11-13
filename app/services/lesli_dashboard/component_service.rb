module LesliDashboard
    class ComponentService < Lesli::ApplicationLesliService
        attr_reader :dashboard

        def initialize(current_user, dashboard_id:)
            super(current_user)
            @dashboard = DashboardService.new(current_user).find(dashboard_id).result
            raise ActiveRecord::RecordNotFound unless @dashboard
        end

        def index
            response(dashboard.components.order(:position, :id))
        end

        def find(id)
            response(dashboard.components.find(id))
        end

        def create(attributes)
            component = dashboard.components.build(component: attributes[:component])
            widget = widgets.find { |definition| definition.identifier == component.component }
            unless widget
                component.errors.add(:component, :invalid)
                return failure(component)
            end

            # Appending and reordering use the same parent lock and transaction.
            dashboard.with_lock do
                component.assign_attributes(widget.options.deep_dup.except(:position))
                component.position = (dashboard.components.maximum(:position) || 0) + 1
                component.save!
            end
            response(component)
        rescue ActiveRecord::RecordInvalid => exception
            failure(exception.record)
        end

        def update(attributes)
            component = resource
            dashboard.with_lock do
                component.reload
                component.size = attributes[:size] if attributes.key?(:size)
                assign_settings(component, attributes.fetch(:config, {}))
                raise ActiveRecord::RecordInvalid.new(component) if component.errors.any?
                component.save!
            end
            response(component)
        rescue ActiveRecord::RecordInvalid => exception
            failure(exception.record)
        end

        def move(direction)
            unless %w[up down].include?(direction)
                resource.errors.add(:position, :invalid)
                return failure(resource)
            end

            dashboard.with_lock do
                components = dashboard.components.order(:position, :id).to_a
                index = components.index { |component| component.id == resource.id }
                target = index + (direction == "up" ? -1 : 1)
                if target.between?(0, components.length - 1)
                    components[index], components[target] = components[target], components[index]
                    # Normalize positions as well as swapping: older layouts may
                    # contain ties, which would otherwise make arrows unpredictable.
                    components.each_with_index { |component, position| component.update!(position: position + 1) }
                end
            end
            response(resource.reload)
        rescue ActiveRecord::RecordInvalid => exception
            resource.errors.add(:base, exception.record.errors.full_messages.to_sentence)
            failure(resource)
        end

        def destroy
            dashboard.with_lock { resource.destroy! }
            response(resource)
        end

        def widgets
            WidgetCatalog.widgets(dashboard.engine)
        end

        private

        def failure(component)
            error(component.errors.full_messages.to_sentence)
            response(component)
        end

        def assign_settings(component, attributes)
            widget = widgets.find { |definition| definition.identifier == component.component }
            # Retired widgets can still be resized or removed, but have no editable options.
            settings = widget ? widget.settings : {}
            config = component.config.deep_dup
            attributes.stringify_keys.slice(*settings.keys.map(&:to_s)).each do |key, value|
                definition = settings.fetch(key.to_sym)
                config[key] = value
                case definition.fetch(:type).to_sym
                when :text
                    config[key] = value.to_s
                when :integer
                    begin
                        config[key] = Integer(value.to_s, 10)
                    rescue ArgumentError
                        component.errors.add(:config, :invalid)
                    end
                when :boolean
                    if [true, false, "true", "false", "1", "0"].include?(value)
                        config[key] = ActiveModel::Type::Boolean.new.cast(value)
                    else
                        component.errors.add(:config, :invalid)
                    end
                when :select
                    component.errors.add(:config, :invalid) unless definition.fetch(:choices).include?(value)
                else
                    raise ArgumentError, "Unsupported widget setting type: #{definition[:type]}"
                end
            end
            component.config = config
        end
    end
end
