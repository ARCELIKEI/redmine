class RiskStatusesController < ApplicationController
  unloadable
  	$real_id
	# displays all risk statuses in the system
	def index
		@risk_statuses  = RiskStatus.all
	end

	# new risk status
	def new_risk_status
		@risk_status = RiskStatus.new
	end

	# create & set its fields
	def create_risk_status

		@risk_status = RiskStatus.new(:status_text => params[:risk_status][:status_text] )

		if @risk_status.save
			flash[:notice] = "Risk Status Created!"
		else
			flash[:error] = "Risk Status cannot be created : #{@risk_statuses.errors.messages}."
		end
		redirect_to :action => :index
	end

	# deletes an existing risk status
	def remove_risk_status
		puts "Id is: "
		@removed_id = params[:id]

		puts @removed_id
		puts @removed_id.is_a? Integer

		@risk_status = RiskStatus.find_by_id( params[:id].to_i ).destroy
		redirect_to :action => :index
	end

	# global variable i
	# ARGUMAN YAP!!!!!
	def edit
		@edited_risk_status = RiskStatus.new
		@temp_id = params[:id].to_i
		puts "In edit: "
		$real_id = @temp_id
	end

	def edit_risk_status
		puts "Id is: "
		puts $real_id
		@edited_risk_status = RiskStatus.find_by_id( $real_id )
		puts "New text is :"
		puts params[:risk_status][:status_text]
		puts "Status is : "
		puts @edited_risk_status
		@edited_risk_status.status_text = params[:risk_status][:status_text]

		if @edited_risk_status.save
			flash[:notice] = "Risk Status Edited!"
		else
			flash[:error] = "Risk Status cannot be edited : #{@risk_statuses.errors.messages}."
		end
		redirect_to :action => :index
	end


end
