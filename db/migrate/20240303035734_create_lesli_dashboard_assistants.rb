class CreateLesliDashboardAssistants < ActiveRecord::Migration[7.0]
  def change
    create_table :lesli_dashboard_assistants do |t|

      t.timestamps
    end
  end
end
