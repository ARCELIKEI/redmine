Redmine::Plugin.register :project_reports do
  name 'Project Reports plugin'
  author 'Arcelik AR-GE!'
  description 'Changes core redmine :('
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'


  menu :project_menu, :project_reports, { :controller => 'project_reports', :action => 'index' }, :caption => :project_reportss, :after => :activity, :param => :project_id

  project_module :project_reports do
    permission :view_project_reports, :project_reports => :index, :require => :member
    permission :download_project_reports, :project_reports => :download
    permission :create_project_reports, :project_reports => [:new, :upload, :delete]
  end

  ActionDispatch::Callbacks.to_prepare  do
    require_dependency 'type_report'
end

end
