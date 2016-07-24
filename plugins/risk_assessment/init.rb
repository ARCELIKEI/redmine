Redmine::Plugin.register :risk_assessment do
  name 'Risk Assessment plugin'
  author 'Arcelik AR-GE!'
  description 'Changes core redmine :('
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'


  add_tab :critical_value, :partial => 'tab/critical_value_set'
  tab_settings :default => {'low_to_mid_threshold' => '2','mid_to_high_threshold' => '5' }

 	permission :risk_statuses, { :risk_statuses => [:index] }, :public => true
  permission :risks, { :risks => [:index] }, :public => true

  menu :admin_menu, :risk_assessment, {:controller => 'risk_statuses', :action => 'index'},
		:caption => :field_risk_statuses

	menu :project_menu, :risk_assessment, { :controller => 'risks', :action => 'index'},
       	:caption => :field_risk_assessment, :param => :project_id

  project_module :risk_assessment do
    permission :risk_assessment, {:risk_assessment => [:index]}, :require => :member
  end

end


#menu :project_menu, :polls, { :controller => 'polls', :action => 'index' }, :caption => 'Polls', :param => :project_id
