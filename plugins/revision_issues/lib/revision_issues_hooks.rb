require 'redmine/scm/adapters/abstract_adapter'
class RevisionIssuesHooks < Redmine::Hook::ViewListener

  def view_issues_form_details_bottom(context={})
    issue = context[:issue]
    project = context[:project]
    @revision_issues = RevisionIssues.where(:issue_id => issue.id)
    selected_changeset = Changeset.new
    selected_revision = selected_changeset.revision
    return unless project.repository
    project.repository.changesets.each do |changeset|
    end
    changesets = project.repository.changesets
    @revisions = []
    changesets.each do |changeset|
      @revisions.push(changeset)
    end
    project_identifier = project.identifier
    context[:controller].send(:render_to_string, {
         :partial => "revision_issues/view",
         :locals =>  {:revisions => @revisions, :selected_revision => selected_revision, :revision_issues => @revision_issues}
      })
  end

  def view_issues_show_details_bottom(context={ })
    issue = context[:issue]
    revision_issues = RevisionIssues.where(:issue_id => issue.id)
    project = context[:project]
    return unless project.repository and  revision_issues
    revision_title = ""
    project.repository.changesets.each do |changeset|
      revision_issues.each do |revision_issue|
        if revision_issue.revision_id == changeset.revision
         revision_title += " - " + changeset.title + "<br/>"
        end
      end
    end
    unless revision_title == ""
      view_string = "<tr><th>Related Commits :</th><td>"
      view_string += "#{revision_title}</td></tr>"
      return "#{view_string}"
    else
      return
    end
  end

  def controller_issues_new_after_save(context={ })
    issue = context[:issue]
    revision_issues = RevisionIssues.where(:issue_id => issue.id)
    if context[:params][:revision_id]
        revision_ids = context[:params][:revision_id]
        revision_issues.each do |revision_issue|
          revision_issue.delete
        end
        revision_ids.each   do |revision_id|
          revision_issue = RevisionIssues.new(:issue_id => issue.id, :revision_id => revision_id)
          revision_issue.save
        end
    else
      revision_issues.each do |revision_issue|
            revision_issue.delete
      end
    end
  end


end
