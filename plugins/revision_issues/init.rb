require 'redmine'

require_dependency 'revision_issues_hooks'

Redmine::Plugin.register :revision_issues do
  name 'Revision Issues plugin'
  author 'Arcelik AR-GE!'
  description 'Changes core redmine :('
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end
