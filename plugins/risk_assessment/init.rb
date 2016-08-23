Redmine::Plugin.register :risk_assessment do
  name 'Risk Assessment plugin'
  author 'Arcelik AR-GE'
  description 'Risk assessment for projects. Need to be selected from project settings.'
  version '0.0.2'
  url 'https://github.com/ARCELIKEI/redmine/tree/arriva-3.0/plugins/risk_assessment'


  add_tab :critical_value, :partial => 'tab/critical_value_set'
  tab_settings :default => {'low_to_mid_threshold' => '2','mid_to_high_threshold' => '5' }

  menu :admin_menu, :risk_assessment, {:controller => 'risk_statuses', :action => 'index'},
		:caption => :field_risk_statuses

	menu :project_menu, :risk_assessment, { :controller => 'risks', :action => 'index'},
       	:caption => :field_risk_assessment, :param => :project_id

  project_module :risk_assessment do
    permission :view_risks, :risks => :index, :require => :member
  end

end
