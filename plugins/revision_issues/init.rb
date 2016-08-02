require 'redmine'

require_dependency 'revision_issues_hooks'

Redmine::Plugin.register :revision_issues do
  name 'Revision Issues plugin'
  author 'Arcelik AR-GE'
  description 'Make relations between issues and revisions.'
  version '0.0.1'
  url 'https://github.com/ARCELIKEI/redmine/tree/arriva-3.0/plugins/revision_issues'
end
