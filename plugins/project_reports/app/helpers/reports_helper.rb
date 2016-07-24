module ReportsHelper
  def format_check_for_file(attachment)

    o_file_name = uploaded_file.original_filename
    o_file_ext = File.extname(o_file_name)
    time_stamp = DateTime.now.strftime("%y%m%d%H%M%S")

    #check if file_ext is in allowed_file_exts
    unless allowed_exts.include? o_file_ext
      flash[:error] = "file type is not allowed"
      redirect_to :action => "index", :project_id => session[:project_id]
      return
    end

    #file_name in the database
    file_name = "PR_"
    file_name += time_stamp
    file_name += o_file_ext

    #file_extension for directory path
    if o_file_ext == ""
      file_ext = "other_extensions"
    else
      file_ext = o_file_ext
    end
  end
end
