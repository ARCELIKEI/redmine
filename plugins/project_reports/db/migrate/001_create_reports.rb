class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|

      t.text :description

      t.string :title

      t.string :path

      t.integer :project_id


    end

  end
end
