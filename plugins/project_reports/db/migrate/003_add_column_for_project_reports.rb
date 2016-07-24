class AddColumnForProjectReports < ActiveRecord::Migration
  def up
    add_column :reports , :upload_date,:datetime #,:default => Time.now
    add_column :reports , :owner_id, :int
    add_column :reports , :size,:float, :default => 0
  end

  def down
    remove_column :reports ,:upload_date
    remove_column :reports ,:owner_id
    remove_column :reports ,:size
  end
end
