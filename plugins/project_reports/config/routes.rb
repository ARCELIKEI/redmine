# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'projects/:project_id/project_reports', :to => 'project_reports#index'
get 'projects/:project_id/project_reports/new', :to => 'project_reports#new'
post 'projects/:project_id/project_reports/upload', :to => 'project_reports#upload'
get 'projects/:project_id/project_reports/download', :to => 'project_reports#download'
get 'projects/:project_id/project_reports/delete', :to => 'project_reports#delete'
