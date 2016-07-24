class Risk < ActiveRecord::Base
  unloadable

  belongs_to :risk_status
  has_many :risk_assignees
end
