class CreateRiskStatuses < ActiveRecord::Migration
  def change
    create_table :risk_statuses do |t|
    	t.string :status_text

    end
  end
end
