class AddProjectIdToRisk < ActiveRecord::Migration
  def change
  	add_column :risks, :project_id, :integer	
  end
end
