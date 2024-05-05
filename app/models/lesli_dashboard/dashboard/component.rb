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
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
=end

module LesliDashboard
    class Dashboard::Component < ApplicationRecord

        belongs_to :dashboard, inverse_of: :components

        def self.component_ids
            ["version"]
        end
        # components_ids: {
        #     list_new_tickets: "list_new_tickets",
        #     list_my_tickets: "list_my_tickets",
        #     list_unassigned_tickets: "list_unassigned_tickets",
        #     chart_tickets_by_type: "chart_tickets_by_type",
        #     chart_tickets_by_category: "chart_tickets_by_category",
        #     hours_worked: "hours_worked"
        # }
    end
end
