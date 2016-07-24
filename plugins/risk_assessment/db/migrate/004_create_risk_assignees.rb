class CreateRiskAssignees < ActiveRecord::Migration
  def change
    create_table :risk_assignees do |t|
    	t.references :risk
    	t.references :user


    end
  end
end
