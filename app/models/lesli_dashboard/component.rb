module LesliDashboard
    class Component < ApplicationRecord
        belongs_to :dashboard
        COMPONENTS_GENERAL = %i[count chart_bar chart_line date weather calendar]
    end
end
