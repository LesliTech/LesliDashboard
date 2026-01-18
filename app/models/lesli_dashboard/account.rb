=begin

Lesli

Copyright (c) 2023, Lesli Technologies, S. A.

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

Made with ♥ by https://www.lesli.tech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.dev
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
=end

module LesliDashboard
    class Account < ApplicationRecord
        belongs_to :account, class_name: "Lesli::Account"

        has_many :dashboards
        has_many :users, class_name: "Lesli::User"

        after_create :initialize_account

        def initialize_account
            initialize_dashboards(self)
        end

        def initialize_dashboards(account)

            # Get all the installed and loaded engines 
            # to register a base dashboard for every engine
            LesliSystem.engines.each do |engine, data|

                # Skip not work module engine
                next if ['Lesli', 'LesliBabel', 'Root'].include?(engine)

                # Create a dashboard for the current engine
                dashboard = account.dashboards
                .create_with(:default => true)
                .find_or_create_by(engine: engine)

                # Get the components registered in every engine dashboard model
                "#{engine}::Dashboard".constantize::COMPONENTS.each do |component|

                    # Add the components to the engine dashboard
                    dashboard.components
                    .create_with(:position => 1, :size => 4)
                    .find_or_create_by(:component => component)
                end
            end
        end
    end
end
