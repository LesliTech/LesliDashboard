module LesliDashboard
    module WidgetCatalog
        Widget = Struct.new(:identifier, :name_key, :partial, :options, :settings, keyword_init: true) do
            def name
                I18n.t(name_key, default: identifier.humanize)
            end
        end

        @providers = {}

        # Use a block so Rails reloads resolve the current model and its COMPONENTS.
        def self.register(engine, &provider)
            @providers[engine] = provider
        end

        def self.engines
            (LesliSystem.engines.keys - %w[Lesli LesliBabel Root] + @providers.keys).uniq
        end

        def self.widgets(engine)
            return [] unless engines.include?(engine)

            declarations = if @providers.key?(engine)
                @providers.fetch(engine).call
            else
                "#{engine}::Dashboard".constantize::COMPONENTS
            end

            declarations.each_with_index.map do |declaration, index|
                identifier, options = declaration.is_a?(Hash) ? declaration.first : [declaration, {}]
                identifier = identifier.to_s
                options = options.deep_symbolize_keys
                Widget.new(
                    identifier: identifier,
                    name_key: options.fetch(:name_key, "#{engine.underscore}.widgets.#{identifier}"),
                    partial: options.fetch(:partial, "#{engine.underscore}/dashboards/component-#{identifier.dasherize}"),
                    settings: options.fetch(:settings, {}),
                    options: { size: 4, position: index + 1, config: {} }.merge(options.slice(:size, :position, :config))
                )
            end
        end
    end
end
