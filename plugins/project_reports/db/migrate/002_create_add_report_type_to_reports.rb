class CreateAddReportTypeToReports < ActiveRecord::Migration
  def change
    add_column :reports, :type_id, :integer
  end
end
