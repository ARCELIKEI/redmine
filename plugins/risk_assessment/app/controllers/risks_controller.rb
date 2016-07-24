class RisksController < ApplicationController
  	unloadable
  	menu_item :risk_assessment
  	before_filter :require_login
  	before_filter :require_project_member_or_admin

  	require 'prawn/table'
  	# require_relative "../lib/prawn/table"

  	$risk_id

  	def index
  		@project = Project.find(params[:project_id])
      @risks  = Risk.where(:project_id => @project.id )

		if ( params[:sort_type] == "asc")
			@sortType = "asc"
			case params[:sorted_attr]		# sort according to clicked link
				when "title_sort"
					@risks = @risks.sort_by{|rs| rs.title}
					@sortAttr = "title_sort"
				when "probability_sort"	# sort by description
					@risks = @risks.sort_by{|rs| rs.probability_value}
					@sortAttr = "probability_sort"
				when "impact_sort"
					@risks = @risks.sort_by{|rs| rs.impact_value}
					@sortAttr = "impact_sort"
				when "risk_sort"
					@risks = @risks.sort_by{|rs| rs.risk_evaluation}
					@sortAttr = "risk_sort"
				when "status_sort"
					@risks = @risks.sort_by{|rs| rs.risk_status.status_text}
					@sortAttr = "status_sort"
				else
						# do NOTHING
			end
		else
			@sortType = "desc"
			case params[:sorted_attr]
				when "title_sort"
					@risks = @risks.sort_by{|rs| rs.title}.reverse
					@sortAttr = "title_sort"
				when "probability_sort"	# sort by description
					@risks = @risks.sort_by{|rs| rs.probability_value}.reverse
					@sortAttr = "probability_sort"
				when "impact_sort"
					@risks = @risks.sort_by{|rs| rs.impact_value}.reverse
					@sortAttr = "impact_sort"
				when "risk_sort"
					@risks = @risks.sort_by{|rs| rs.risk_evaluation}.reverse
					@sortAttr = "risk_sort"
				when "status_sort"
					@risks = @risks.sort_by{|rs| rs.risk_status.status_text}.reverse
					@sortAttr = "status_sort"
				else
						# do NOTHING
			end
		end


		# params[:project_id] returns the identifier  of this project;
		# but, let's set it to "id" of the project!
		#### Clean
		#### if nt used assignees exist
		@removed_assignee = []
		@removed_assignee = RiskAssignee.where(:risk_id => -1)
		if @removed_assignee.length > 0
			@removed_assignee.each do |ass|
				ass.destroy
			end
		end
		@settings = TabSetting.get_settings(@project.id)['risk_assessment']

		respond_to do |format|
			format.pdf do
				send_data generate_project_risks_pdf( @project, @risks, @settings), :filename => "Project##{@project.id}_#{@project.name}_risks.pdf", :type => "application/pdf"
			end
			format.xls do
				generate_project_risks_spreadsheet( @project, @risks, @settings)
			end
			format.html
	  	end

  	end

	# new risk
	def new
		@project = Project.find(params[:project_id])
		@riskStatusCount = RiskStatus.count
		if @riskStatusCount == 0
			render_error l(:error_no_risk_status)
	      	return false
	    end
		@users = User.all
		@risk = Risk.new
		@risk_assignee = RiskAssignee.new
	end

	# create & set fields of risk
	def create
		@project = Project.find(params[:project_id])

		@risk = Risk.new()
		@risk.title = params[:risk][:title]
		@risk.description = params[:risk][:description]
		@risk.trigger_event = params[:risk][:trigger_event]
		@risk.mitigation_contingency = params[:risk][:mitigation_contingency]
		@risk.probability_value = (params[:risk][:probability_value]).to_f * 10     ## since prob value is 0.1, 0.2, 0.3, and in database it is integer,
		@risk.impact_value = params[:risk][:impact_value].to_i						 ## multiply by 10 to have integer, but printing it in index.html, divide by 10

		@risk.risk_evaluation = (((@risk.probability_value).to_f / 10.0) * @risk.impact_value) * 10  ## risk evaluation is integer in database, but it is
																								## actually float, risk_eval = risk_prob_value * risk_impact
		puts "Status ID: "
		puts params[:risk][:risk_status_id]



		if params[:risk][:risk_status_id].nil? || RiskStatus.all.length < 1 || params[:risk][:risk_status_id].to_i < 1
			redirect_to :action => :index
			flash[:error] = "Risk Status cannot be found."
			return
		else
			@risk.risk_status_id = params[:risk][:risk_status_id]
		end

		@risk.project_id = @project.id

		@temp_risk_assignees = []
		@temp_risk_assignees = RiskAssignee.where(:risk_id => -1)


		if @risk.save
			if ( @temp_risk_assignees.length > 0 )
				@temp_risk_assignees.each do |ass|
					ass.risk_id = @risk.id
					ass.save
				end
			end
			flash[:notice] = "Risk Created!"
		else
			flash[:error] = "Risk cannot be created : #{@risks.errors.messages}."
		end
		redirect_to :action => :index
	end

	# deletes an existing risk status
	def remove

		@assignees = RiskAssignee.where(:risk_id => params[:id].to_i)
		@risk = Risk.find_by_id( params[:id].to_i ).destroy

		@assignees.each do |ass|
			ass.destroy
		end

		redirect_to :action => :index
	end

	def edit
		@project = Project.find(params[:project_id])
		@all_assignees = []
		@edited_risk = Risk.new()
		if params[:from] == "First Edit"
			$risk_id = params[:id].to_i
		end
		@edited_risk = Risk.find_by_id( $risk_id )
		@all_assignees = RiskAssignee.where(:risk_id => $risk_id)
	end


	def edit_save
		@project = Project.find(params[:project_id])

		@all_assignees = RiskAssignee.where(:risk_id => $risk_id)
		@edited_risk = Risk.find($risk_id)

		@edited_risk.title = params[:risk][:title]
		@edited_risk.description = params[:risk][:description]
		@edited_risk.trigger_event = params[:risk][:trigger_event]
		@edited_risk.mitigation_contingency = params[:risk][:mitigation_contingency]
		@edited_risk.probability_value = (params[:risk][:probability_value]).to_f * 10

		@edited_risk.impact_value = params[:risk][:impact_value].to_i
	#	@edited_risk.critical_value = params[:risk][:critical_value].to_i
		@edited_risk.risk_evaluation = (((@edited_risk.probability_value).to_f / 10.0) * @edited_risk.impact_value) * 10
		@edited_risk.risk_status_id = params[:risk][:risk_status_id]
		@edited_risk.project_id = @project.id

		if @edited_risk.save
			flash[:notice] = "Risk Edited!"
		else
			flash[:error] = "Risk cannot be edited : #{@risks.errors.messages}."
		end
		redirect_to :action => :index
	end

	def edit_add_risk_assignee
		@project = Project.find(params[:project_id])
		@risk_assignee = RiskAssignee.new
	end

	def edit_add_risk_assignee_set
		@risk_assignee = RiskAssignee.new
		@risk_assignee.risk_id = $risk_id
		@risk_assignee.user_id = params[:risk_assignee][:user_id]
		@risk_assignee.save
		redirect_to :action => :edit

	end

	def edit_remove_risk_assignee
		@risk_assignee = RiskAssignee.find_by_id( params[:id].to_i ).destroy
		redirect_to :action => :edit
	end

	def create_add_risk_assignee
		@project = Project.find(params[:project_id])
		@risk_assignee = RiskAssignee.new
	end

	def create_add_risk_assignee_set
		@risk_assignee = RiskAssignee.new
		@risk_assignee.risk_id = -1
		@risk_assignee.user_id = params[:risk_assignee][:user_id]
		@risk_assignee.save
		redirect_to :action => :new
	end

	def create_remove_risk_assignee
		@risk_assignee = RiskAssignee.find_by_id( params[:id].to_i ).destroy
		redirect_to :action => :new
	end

	def show
		@project = Project.find(params[:project_id])
		@risk = Risk.find( params[:risk_id].to_i )
		@settings = TabSetting.get_settings(@project.id)['risk_assessment']
		respond_to do |format|
			format.pdf do
				send_data generate_risk_pdf( @project, @risk, @settings), :filename => "Risk##{@risk.id}_#{@risk.title}.pdf", :type => "application/pdf"
			end
			format.html
	  	end
	end

  	def generate_risk_pdf(project,risk,setting)

		pdf = Prawn::Document.new(:left_margin => 50, :page_size => 'A4', :page_layout => :landscape)
		pdf.font_families.update("DejaVuSans" => {
	        :normal => "#{Rails.root}/lib/fonts/dejavu/DejaVuSans.ttf",
	        :italic => "#{Rails.root}/lib/fonts/dejavu/DejaVuSansMono.ttf",
	        :bold => "#{Rails.root}/lib/fonts/dejavu/DejaVuSans-Bold.ttf",
	        :bold_italic => "#{Rails.root}/lib/fonts/dejavu/DejaVuSans-BoldOblique.ttf"
	    })
	    pdf.font("DejaVuSans")
	    pdf.font_size = 8

	    pdf.draw_text "risk##{risk.id}".upcase, :at => [0, 500], :size => 12, :style => :bold
	    pdf.draw_text " #{Date.today}".upcase, :at => [650, 500], :size => 12, :style => :bold
 		pdf.move_down(50)

	    pdf.text "<font size='15'>#{project.name}</font>", :inline_format => true, :style => :bold
	    pdf.text "<font size='12'>#{risk.title}</font>", :inline_format => true, :style => :bold
		pdf.move_down(20)

	    data_values = 		[	["Probability Value","Impact Value","Risk Evaluation"],
								[risk.probability_value/10.0,risk.impact_value,risk.risk_evaluation/10.0],
							]

		pdf.table( data_values,	:header => false, :cell_style => {:inline_format => true }, :row_colors => ["FFFFCC"]) do |table|

			table.column_widths = 200
	        table.row(0).background_color = "CCCCCC"
	        table.row(0).border_width = 2

	        table.row(1..(table.row_length-1)).column(2).filter { |cell| cell.content.to_f < setting['low_to_mid_threshold'].to_f }.
	        	background_color = "9AFE2E"
	        table.row(1..(table.row_length-1)).column(2).filter { |cell| cell.content.to_f >= setting['mid_to_high_threshold'].to_f }.
	        	background_color = "FE2E2E"
	        table.row(1..(table.row_length-1)).column(2).filter { |cell| ( cell.content.to_f >= setting['low_to_mid_threshold'].to_f ) and ( cell.content.to_f < setting['mid_to_high_threshold'].to_f ) }.
	        	background_color = "FFCC00"

		end
		pdf.move_down(20)

		pdf.text "<font size='10'>Threshoolds for risk</font>", :inline_format => true, :style => :bold
	    pdf.move_down(5)

		setting_values = 	[	["Low to Middle Threshoold","Middle to High Threshold"],
								[setting['low_to_mid_threshold'],setting['mid_to_high_threshold']]
							]

		pdf.table( setting_values,	:header => false, :cell_style => {:inline_format => true }, :row_colors => ["F6F7F8"]) do |table|

			table.column_widths = 200
	        table.row(0).background_color = "CCCCCC"
	        table.row(0).border_width = 2

		end
		pdf.move_down(20)

		pdf.text "<font size='10'>Description</font>", :inline_format => true, :style => :bold
		pdf.move_down(5)
        @description = ActionController::Base.helpers.strip_tags(Redmine::WikiFormatting.to_html(Setting.text_formatting,  @risk.description))

        pdf.text "#{@description}"
        pdf.move_down(20)

        pdf.text "<font size='10'>Trigger Event</font>", :inline_format => true, :style => :bold
		pdf.move_down(5)
        @trigger_event = ActionController::Base.helpers.strip_tags(Redmine::WikiFormatting.to_html(Setting.text_formatting,  @risk.trigger_event))

        pdf.text "#{@trigger_event}"
        pdf.move_down(20)

		pdf.text "<font size='10'>Mitigation & Contingency Plan</font>", :inline_format => true, :style => :bold
		pdf.move_down(5)
        @mitigation_contingency = ActionController::Base.helpers.strip_tags(Redmine::WikiFormatting.to_html(Setting.text_formatting,  @risk.mitigation_contingency))

        pdf.text "#{@mitigation_contingency}"
        pdf.move_down(20)


        pdf.render

  	end

  	def generate_project_risks_pdf(project,risks,setting)

  		pdf = Prawn::Document.new(:left_margin => 50, :page_size => 'A4', :page_layout => :landscape)
		pdf.font_families.update("DejaVuSans" => {
	        :normal => "#{Rails.root}/lib/fonts/dejavu/DejaVuSans.ttf",
	        :italic => "#{Rails.root}/lib/fonts/dejavu/DejaVuSansMono.ttf",
	        :bold => "#{Rails.root}/lib/fonts/dejavu/DejaVuSans-Bold.ttf",
	        :bold_italic => "#{Rails.root}/lib/fonts/dejavu/DejaVuSans-BoldOblique.ttf"
	    })
	    pdf.font("DejaVuSans")
	    pdf.font_size = 8

	    pdf.draw_text "project##{project.id} - #{project.name}".upcase, :at => [0, 500], :size => 12, :style => :bold
	    pdf.draw_text " #{Date.today}".upcase, :at => [650, 500], :size => 12, :style => :bold
 		pdf.move_down(50)

	 	pdf.text "<font size='15'>Risks</font>", :inline_format => true, :style => :bold
		pdf.move_down(20)

	   	risk_table_values = 		[	["Title","Probability Value","Impact Value","Risk Evaluation","Risk Status","Assigned To"]	]

		risks.each do |r|
			to_push = []
			to_push.push r.title
			to_push.push r.probability_value/10.0
			to_push.push r.impact_value
			to_push.push r.risk_evaluation/10.0
			to_push.push RiskStatus.find( r.risk_status_id ).status_text

			assignees = "";
			@allAssignessOfRisk = RiskAssignee.where(:risk_id => r.id)
			@allAssignessOfRisk.each do |assignee|
				assignees = assignees + User.find( assignee.user_id ).name
				assignees = assignees + "\n"
			end
			to_push.push assignees

			risk_table_values.push to_push
		end

		pdf.table( risk_table_values,	:header => false, :cell_style => {:inline_format => true }, :row_colors => ["F6F7F8"]) do |table|

	        table.row(0).background_color = "CCCCCC"
	        table.row(0).border_width = 2

	        table.row(1..(table.row_length-1)).column(3).filter { |cell| cell.content.to_f < setting['low_to_mid_threshold'].to_f }.
	        	background_color = "9AFE2E"
	        table.row(1..(table.row_length-1)).column(3).filter { |cell| cell.content.to_f >= setting['mid_to_high_threshold'].to_f }.
	        	background_color = "FE2E2E"
	        table.row(1..(table.row_length-1)).column(3).filter { |cell| ( cell.content.to_f >= setting['low_to_mid_threshold'].to_f ) and ( cell.content.to_f < setting['mid_to_high_threshold'].to_f ) }.
	        	background_color = "FFCC00"
		end
		pdf.move_down(20)

		pdf.text "<font size='10'>Threshoolds for risks</font>", :inline_format => true, :style => :bold
	    pdf.move_down(5)

		setting_values = 	[	["Low to Middle Threshoold","Middle to High Threshold"],
								[setting['low_to_mid_threshold'],setting['mid_to_high_threshold']]
							]

		pdf.table( setting_values,	:header => false, :cell_style => {:inline_format => true }, :row_colors => ["F6F7F8"]) do |table|

			table.column_widths = 200
	        table.row(0).background_color = "CCCCCC"
	        table.row(0).border_width = 2
	    end

        pdf.render

  	end

  	def generate_project_risks_spreadsheet(project,risks,setting)

		risk_table_headers = 		["Title","Probability Value","Impact Value","Risk Evaluation","Risk Status","Assigned To"]
    	risk_table_columns = 		["title","probability_value","impact_value","risk_evaluation","risk_status","assignees"]

   		risk_table_values = []
   		risks.each do |r|
			to_push = {}
			to_push[:title] = r.title
			to_push[:probability_value] = r.probability_value/10.0
			to_push[:impact_value] = r.impact_value
			to_push[:risk_evaluation] =  r.risk_evaluation
			to_push[:risk_status] = RiskStatus.find( r.risk_status_id ).status_text

			assignees = "";
			@allAssignessOfRisk = RiskAssignee.where(:risk_id => r.id)
			@allAssignessOfRisk.each do |assignee|
				assignees = assignees + User.find( assignee.user_id ).name
				assignees = assignees + " "
			end
			to_push[:assignees] = assignees

			risk_table_values.push OpenStruct.new to_push
		end

    	render :xls => risk_table_values,
                     :columns => risk_table_columns,
                     :headers => risk_table_headers
  	end


  	def require_project_member_or_admin

  		if User.current.admin == true
  			return true
  		end

  		@project_member_ids = Project.find(params[:project_id]).users.collect{|u| u.id}
  		@current_login_id = User.current.id

  		if @project_member_ids.include?(@current_login_id)
  			return true
  		else
  			redirect_to :action => :index, :controller => 'projects'
  			flash[:error] = "You are not a member for this project."
			return
  		end

  	end
end
