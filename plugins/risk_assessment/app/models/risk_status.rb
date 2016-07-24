class RiskStatus < ActiveRecord::Base
  unloadable

  has_many :risks
end
