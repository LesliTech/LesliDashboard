module LesliDashboard
    class Component < ApplicationRecord
        self.table_name = "lesli_dashboard_components"

        belongs_to :dashboard, inverse_of: :components
        validates :component, presence: true
        validates :size, numericality: { only_integer: true, in: 1..12 }
        validates :position, numericality: { only_integer: true, greater_than: 0 }
        validate :config_is_an_object

        COMPONENTS_GENERAL = %i[count chart_bar chart_line date weather calendar].freeze

        private

        def config_is_an_object
            errors.add(:config, :invalid) unless config.is_a?(Hash)
        end
    end
end
