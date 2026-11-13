module LesliDashboard
    module Shared
        class Dashboard < ::Lesli::ApplicationLesliRecord
            self.table_name = "lesli_dashboard_dashboards"
            self.abstract_class = true

            belongs_to :account, class_name: "LesliDashboard::Account", inverse_of: :dashboards
            has_many :components, class_name: "LesliDashboard::Component", inverse_of: :dashboard

            normalizes :name, with: ->(name) { name.strip }
            validates :name, :engine, presence: true
            attr_readonly :account_id, :engine

            COMPONENTS = [].freeze
        end
    end
end
