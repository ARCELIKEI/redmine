# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html


#Added by Fatih Hafizoglu
get  'projects/:project_id/risks', :to => 'risks#index'
get  'projects/:project_id/risks/new', :to => 'risks#new'
post 'projects/:project_id/risks/create', :to => 'risks#create'
get  'projects/:project_id/risks/remove', :to => 'risks#remove'
get  'projects/:project_id/risks/edit', :to => 'risks#edit'
put  'projects/:project_id/risks/edit_save', :to => 'risks#edit_save'
get  'projects/:project_id/risks/show/:risk_id', :to => 'risks#show'

get  'projects/:project_id/risks/create_add_risk_assignee', :to => 'risks#create_add_risk_assignee'
post 'projects/:project_id/risks/create_add_risk_assignee_set', :to => 'risks#create_add_risk_assignee_set'
post  'projects/:project_id/risks/create_remove_risk_assignee', :to => 'risks#create_remove_risk_assignee'

get  'projects/:project_id/risks/edit_add_risk_assignee', :to => 'risks#edit_add_risk_assignee'
post 'projects/:project_id/risks/edit_add_risk_assignee_set', :to => 'risks#edit_add_risk_assignee_set'
post 'projects/:project_id/risks/edit_remove_risk_assignee', :to => 'risks#edit_remove_risk_assignee'


#### RISK STATUSES FOR ADMIN
get 'risk_assessment/index', :to => 'risk_statuses#index', :as => 'index'
get 'risk_assessment/new_risk_status', :to => 'risk_statuses#new_risk_status', :as => 'new_risk_status'
# get 'risk_assessment/create_risk_status', :to => 'risk_statuses#create_risk_status', :as => 'create_risk_status'
post 'risk_assessment/create_risk_status', :to => 'risk_statuses#create_risk_status', :as => 'create_risk_status'
get 'risk_assessment/remove_risk_status', :to => 'risk_statuses#remove_risk_status', :as => 'remove_risk_status'
get 'risk_assessment/edit', :to => 'risk_statuses#edit', :as => 'edit'
# get 'risk_assessment/edit_risk_status', :to => 'risk_statuses#edit_risk_status', :as => 'edit_risk_status'
post 'risk_assessment/edit_risk_status', :to => 'risk_statuses#edit_risk_status', :as => 'edit_risk_status'

#### RISKS FOR EACH PROJECT
