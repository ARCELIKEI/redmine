class AddMitigationContingencyPlanningToRisk < ActiveRecord::Migration
  def change
  	add_column :risks, :mitigation_contingency, :text
  end
end
