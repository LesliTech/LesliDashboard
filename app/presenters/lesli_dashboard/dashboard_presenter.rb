module LesliDashboard
    class DashboardPresenter
        # Literal classes keep every supported width discoverable by Tailwind.
        WIDTH_CLASSES = {
            1 => "md:col-span-6 lg:col-span-1",
            2 => "md:col-span-6 lg:col-span-2",
            3 => "md:col-span-6 lg:col-span-3",
            4 => "md:col-span-6 lg:col-span-4",
            5 => "md:col-span-6 lg:col-span-5",
            6 => "md:col-span-6 lg:col-span-6",
            7 => "md:col-span-12 lg:col-span-7",
            8 => "md:col-span-12 lg:col-span-8",
            9 => "md:col-span-12 lg:col-span-9",
            10 => "md:col-span-12 lg:col-span-10",
            11 => "md:col-span-12 lg:col-span-11",
            12 => "md:col-span-12 lg:col-span-12",
        }.freeze

        def initialize(dashboard)
            @dashboard = dashboard
        end

        def width_class(component)
            WIDTH_CLASSES.fetch(component.size, WIDTH_CLASSES.fetch(4))
        end

        def partial_path(component)
            "#{@dashboard.engine.underscore}/dashboards/component-#{component.component.dasherize}"
        end
    end
end
