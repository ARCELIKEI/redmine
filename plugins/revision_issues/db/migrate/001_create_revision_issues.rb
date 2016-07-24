class CreateRevisionIssues < ActiveRecord::Migration
  def change
    create_table :revision_issues do |t|
      t.string :revision_id
      t.string :issue_id
    end
  end
end
