class ProjectReportsController < ApplicationController
  menu_item :project_reports
  before_filter :find_project_by_project_id ,:authorize
  helper :sort
  include SortHelper



  def index
    session[:plugin_url] = "#{url_for(:only_path => false)}"

	  sort_init 'reporttitle', 'asc'
    sort_update 'reporttitle' => "#{Reports.table_name}.title",
                'reportdescription' => "#{Reports.table_name}.description",
                'reportuploaddate' => "#{Reports.table_name}.upload_date",
                'reportsize' => "#{Reports.table_name}.size",
                'reportowner' => "#{Reports.table_name}.owner_id",
                'reporttype' => "#{Reports.table_name}.type_id"

    @project_id = params[:project_id]
    session[:project_id] = params[:project_id]
    @reports = Reports.where(:project_id => @project.id).order(sort_clause)
  end

  def upload
    attachments = params[:attachments]
    if attachments.is_a?(Hash)
        attachments = attachments.values
    end
    report_type = params[:post][:report_type]
    attachmentNames = ""
    if attachments.is_a?(Array)
      attachments.each_with_index do |attachment,i|
        a = nil
        if uploaded_to = attachment['file']
          next unless uploaded_to.size > 0
          file_name = uploaded_to.original_filename
          time_stamp = DateTime.now.strftime("%y%m%d%H%M%S")
          if(attachment['title'] == "")
            attachment['title'] = file_name.split('.')[0];
          end

          file_name =  time_stamp + "_" + file_name
          FileUtils.mkdir_p('plugins/project_reports/uploads/' + session[:project_id])
          File.open(Rails.root.join('plugins/project_reports', 'uploads',session[:project_id],file_name),'wb') do |file|
            file.write(uploaded_to.read)
          end
          project_id = Project.find(params[:project_id]).id
          post = Reports.new
          post.update_attributes(:description => attachment['description'], :title => attachment['title'], :path => Rails.root.join('plugins/project_reports', 'uploads',session[:project_id],file_name).to_s, :project_id => project_id,:upload_date => Time.now, :size =>uploaded_to.size, :owner_id => User.current.id, :type_id => report_type)
          if(post.save)
            flash[:notice] = "Successfully uploaded!"
            if((i+1) == attachments.size)
              attachmentNames << uploaded_to.original_filename
            else
              attachmentNames << uploaded_to.original_filename << ','
            end
          else
            flash[:error] = "Error occured!"
          end
        end
      end
      Mailer.project_report_added(User.current,attachmentNames,@project,session[:plugin_url]).deliver if params[:send_information]
    end
    redirect_to :action => 'index', :project_id => session[:project_id]
	end


  def download
	  send_file params[:path]
  end

  def delete
	  report = Reports.find(params[:report_id])
    if(User.current.id == report.owner_id || User.current.admin)
      File.delete(report.path)
      if report.delete
          flash[:notice] = "Successfully deleted!"
      else
          flash[:error] = "Error occured!"
      end
      redirect_to :action => 'index', :project_id => session[:project_id]
    else

    end
  end

  def new
    if(Enumeration.where(:type => 'TypeReport').size() == 0)
       flash[:error] = "You should define project type enumerations first!"
       redirect_to :action => 'index', :project_id => session[:project_id]
    end
  end
end
