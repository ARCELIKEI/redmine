class CreateRisks < ActiveRecord::Migration
  def change
    create_table :risks do |t|
    	t.string :description
    	t.integer :probability_value 
    	t.integer :impact_value
    	t.integer :critical_value
    	t.integer :risk_evaluation
    	t.references :risk_status
    	#### MULTIPLE ASSIGNEE

    end
  end
end
