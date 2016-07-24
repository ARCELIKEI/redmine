class AddTittleAndTriggerEventToRisk < ActiveRecord::Migration
  def change
  	add_column :risks, :title, :string
  	add_column :risks, :trigger_event, :text
  end
end
