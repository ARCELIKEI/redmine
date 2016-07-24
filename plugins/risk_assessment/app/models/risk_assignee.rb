class RiskAssignee < ActiveRecord::Base
  unloadable
  belongs_to :risk 
  belongs_to :user
end
