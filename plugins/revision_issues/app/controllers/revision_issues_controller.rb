class RevisionIssues < ActiveRecord::Base
  unloadable

  def commit
       read_attribute(:requirement_id)
  end
end
