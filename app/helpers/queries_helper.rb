# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2016  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module QueriesHelper
  include ApplicationHelper

  def filters_options_for_select(query)
    ungrouped = []
    grouped = {}
    query.available_filters.map do |field, field_options|
      if [:tree, :relation].include?(field_options[:type]) 
        group = :label_relations
      elsif field =~ /^(.+)\./
        # association filters
        group = "field_#{$1}"
      elsif %w(member_of_group assigned_to_role).include?(field)
        group = :field_assigned_to
      elsif field_options[:type] == :date_past || field_options[:type] == :date
        group = :label_date
      end
      if group
        (grouped[group] ||= []) << [field_options[:name], field]
      else
        ungrouped << [field_options[:name], field]
      end
    end
    # Don't group dates if there's only one (eg. time entries filters)
    if grouped[:label_date].try(:size) == 1 
      ungrouped << grouped.delete(:label_date).first
    end
    s = options_for_select([[]] + ungrouped)
    if grouped.present?
      localized_grouped = grouped.map {|k,v| [l(k), v]}
      s << grouped_options_for_select(localized_grouped)
    end
    s
  end


  def retrieve_query_for_team_managers(members)
    @query = IssueQuery.new(:name => "_")
    @query.build_from_params(params)
    @query.project = nil
    filter = Hash.new
    if params[:v]
      filter["assigned_to_id"] = {:operator=>"=", :values=>members.map {|s| s.to_s} & params[:v]["assigned_to_id"]}
    else
      filter["assigned_to_id"] = {:operator=>"=", :values=>members.map {|s| s.to_s}}
    end
    @query.filters["assigned_to_id"] = filter["assigned_to_id"]
    session[:query] = nil
  end

  def query_filters_hidden_tags(query)
    tags = ''.html_safe
    query.filters.each do |field, options|
      tags << hidden_field_tag("f[]", field, :id => nil)
      tags << hidden_field_tag("op[#{field}]", options[:operator], :id => nil)
      options[:values].each do |value|
        tags << hidden_field_tag("v[#{field}][]", value, :id => nil)
      end
    end
    tags
  end

  def query_columns_hidden_tags(query)
    tags = ''.html_safe
    query.columns.each do |column|
      tags << hidden_field_tag("c[]", column.name, :id => nil)
    end
    tags
  end

  def query_hidden_tags(query)
    query_filters_hidden_tags(query) + query_columns_hidden_tags(query)
  end

  def available_block_columns_tags(query)
    tags = ''.html_safe
    query.available_block_columns.each do |column|
      tags << content_tag('label', check_box_tag('c[]', column.name.to_s, query.has_column?(column), :id => nil) + " #{column.caption}", :class => 'inline')
    end
    tags
  end

  def available_totalable_columns_tags(query)
    tags = ''.html_safe
    query.available_totalable_columns.each do |column|
      tags << content_tag('label', check_box_tag('t[]', column.name.to_s, query.totalable_columns.include?(column), :id => nil) + " #{column.caption}", :class => 'inline')
    end
    tags << hidden_field_tag('t[]', '')
    tags
  end

  def query_available_inline_columns_options(query)
    (query.available_inline_columns - query.columns).reject(&:frozen?).collect {|column| [column.caption, column.name]}
  end

  def query_selected_inline_columns_options(query)
    (query.inline_columns & query.available_inline_columns).reject(&:frozen?).collect {|column| [column.caption, column.name]}
  end

  def render_query_columns_selection(query, options={})
    tag_name = (options[:name] || 'c') + '[]'
    render :partial => 'queries/columns', :locals => {:query => query, :tag_name => tag_name}
  end

  def render_query_totals(query)
    return unless query.totalable_columns.present?
    totals = query.totalable_columns.map do |column|
      total_tag(column, query.total_for(column))
    end
    content_tag('p', totals.join(" ").html_safe, :class => "query-totals")
  end

  def total_tag(column, value)
    label = content_tag('span', "#{column.caption}:")
    value = content_tag('span', format_object(value), :class => 'value')
    content_tag('span', label + " " + value, :class => "total-for-#{column.name.to_s.dasherize}")
  end

  def column_header(column)
    column.sortable ? sort_header_tag(column.name.to_s, :caption => column.caption,
                                                        :default_order => column.default_order) :
                      content_tag('th', h(column.caption))
  end

  def column_content(column, issue)
    value = column.value_object(issue)
    if value.is_a?(Array)
      if column.name.to_s == "commit"
        value.collect {|v| column_value(column, issue, v[:revision_id])}.compact.sort.join(', ').html_safe
      else
        value.collect {|v| column_value(column, issue, v)}.compact.join(', ').html_safe
      end
    else
      column_value(column, issue, value)
    end
  end
  
  def column_value(column, issue, value)
    case column.name
    when :id
      link_to value, issue_path(issue)
    when :subject
      link_to value, issue_path(issue)
    when :commit
      link_to(h(value), :controller => "repositories", :action => "revision", :rev => value, :id => "#{@project.identifier}")
    when :parent
      value ? (value.visible? ? link_to_issue(value, :subject => false) : "##{value.id}") : ''
    when :description
      issue.description? ? content_tag('div', textilizable(issue, :description), :class => "wiki") : ''
    when :done_ratio
      progress_bar(value)
    when :relations
      content_tag('span',
        value.to_s(issue) {|other| link_to_issue(other, :subject => false, :tracker => false)}.html_safe,
        :class => value.css_classes_for(issue))
    else
      format_object(value)
    end
  end

  def csv_content(column, issue)
    value = column.value_object(issue)
    if value.is_a?(Array)
      value.collect {|v| csv_value(column, issue, v)}.compact.join(', ')
    else
      csv_value(column, issue, value)
    end
  end

  def csv_value(column, object, value)
    format_object(value, false) do |value|
      case value.class.name
      when 'Float'
        sprintf("%.2f", value).gsub('.', l(:general_csv_decimal_separator))
      when 'IssueRelation'
        value.to_s(object)
      when 'Issue'
        if object.is_a?(TimeEntry)
          "#{value.tracker} ##{value.id}: #{value.subject}"
        else
          value.id
        end
      else
        value
      end
    end
  end

  def query_to_csv(items, query, options={})
    options ||= {}
    columns = (options[:columns] == 'all' ? query.available_inline_columns : query.inline_columns)
    query.available_block_columns.each do |column|
      if options[column.name].present?
        columns << column
      end
    end

    Redmine::Export::CSV.generate do |csv|
      # csv header fields
      csv << columns.map {|c| c.caption.to_s}
      # csv lines
      items.each do |item|
        csv << columns.map {|c| csv_content(c, item)}
      end
    end
  end

  # Retrieve query from session or build a new query
  def retrieve_query
    if !params[:query_id].blank?
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = IssueQuery.where(cond).find(params[:query_id])
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
      session[:query] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    elsif api_request? || params[:set_filter] || session[:query].nil? || session[:query][:project_id] != (@project ? @project.id : nil)
      # Give it a name, required to be valid
      @query = IssueQuery.new(:name => "_")
      @query.project = @project
      @query.build_from_params(params)
      session[:query] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names, :totalable_names => @query.totalable_names}
    else
      # retrieve from session
      @query = nil
      @query = IssueQuery.find_by_id(session[:query][:id]) if session[:query][:id]
      @query ||= IssueQuery.new(:name => "_", :filters => session[:query][:filters], :group_by => session[:query][:group_by], :column_names => session[:query][:column_names], :totalable_names => session[:query][:totalable_names])
      @query.project = @project
    end
  end

  def retrieve_query_from_session
    if session[:query]
      if session[:query][:id]
        @query = IssueQuery.find_by_id(session[:query][:id])
        return unless @query
      else
        @query = IssueQuery.new(:name => "_", :filters => session[:query][:filters], :group_by => session[:query][:group_by], :column_names => session[:query][:column_names], :totalable_names => session[:query][:totalable_names])
      end
      if session[:query].has_key?(:project_id)
        @query.project_id = session[:query][:project_id]
      else
        @query.project = @project
      end
      @query
    end
  end

  # Returns the query definition as hidden field tags
  def query_as_hidden_field_tags(query)
    tags = hidden_field_tag("set_filter", "1", :id => nil)

    if query.filters.present?
      query.filters.each do |field, filter|
        tags << hidden_field_tag("f[]", field, :id => nil)
        tags << hidden_field_tag("op[#{field}]", filter[:operator], :id => nil)
        filter[:values].each do |value|
          tags << hidden_field_tag("v[#{field}][]", value, :id => nil)
        end
      end
    end
    if query.column_names.present?
      query.column_names.each do |name|
        tags << hidden_field_tag("c[]", name, :id => nil)
      end
    end
    if query.totalable_names.present?
      query.totalable_names.each do |name|
        tags << hidden_field_tag("t[]", name, :id => nil)
      end
    end
    if query.group_by.present?
      tags << hidden_field_tag("group_by", query.group_by, :id => nil)
    end

    tags
  end

  private
  def sql_for_field(query_given, field, operator, value, db_table, db_field, is_custom_filter=false)
    puts "sql_for_field >> #{query_given.type_for(field)}"
    sql = ''
    case operator
      when "="
        if value.any?
          case query_given.type_for(field)
            when :date, :date_past
              sql = date_clause(db_table, db_field, (Date.parse(value.first) rescue nil), (Date.parse(value.first) rescue nil))
            when :integer
              if is_custom_filter
                sql = "(#{db_table}.#{db_field} <> '' AND CAST(#{db_table}.#{db_field} AS decimal(60,3)) = #{value.first.to_i})"
              else
                sql = "#{db_table}.#{db_field} = #{value.first.to_i}"
              end
            when :float
              if is_custom_filter
                sql = "(#{db_table}.#{db_field} <> '' AND CAST(#{db_table}.#{db_field} AS decimal(60,3)) BETWEEN #{value.first.to_f - 1e-5} AND #{value.first.to_f + 1e-5})"
              else
                sql = "#{db_table}.#{db_field} BETWEEN #{value.first.to_f - 1e-5} AND #{value.first.to_f + 1e-5}"
              end
            else
              sql = field.eql?("created_at") ? date_clause(db_table, db_field, (Date.parse(value.first) rescue nil), (Date.parse(value.first) rescue nil)) : "#{db_table}.#{db_field} IN (" + value.collect{|val| "'#{ActiveRecord::Base.connection.quote_string(val)}'"}.join(",") + ")"
          end
        else
          # IN an empty set
          sql = "1=0"
        end
      when "!"
        if value.any?
          sql = "(#{db_table}.#{db_field} IS NULL OR #{db_table}.#{db_field} NOT IN (" + value.collect{|val| "'#{ActiveRecord::Base.connection.quote_string(val)}'"}.join(",") + "))"
        else
          # NOT IN an empty set
          sql = "1=1"
        end
      when "!*"
        sql = "#{db_table}.#{db_field} IS NULL"
        sql << " OR #{db_table}.#{db_field} = ''" if is_custom_filter
      when "*"
        sql = "#{db_table}.#{db_field} IS NOT NULL"
        sql << " AND #{db_table}.#{db_field} <> ''" if is_custom_filter
      when ">="
        if [:date, :date_past].include?(query_given.type_for(field)) || field.eql?("created_at")
          sql = date_clause(db_table, db_field, (Date.parse(value.first) rescue nil), nil)
        else
          if is_custom_filter
            sql = "(#{db_table}.#{db_field} <> '' AND CAST(#{db_table}.#{db_field} AS decimal(60,3)) >= #{value.first.to_f})"
          else
            sql = "#{db_table}.#{db_field} >= #{value.first.to_f}"
          end
        end
      when "<="
        if [:date, :date_past].include?(query_given.type_for(field)) || field.eql?("created_at")
          sql = date_clause(db_table, db_field, nil, (Date.parse(value.first) rescue nil))
        else
          if is_custom_filter
            sql = "(#{db_table}.#{db_field} <> '' AND CAST(#{db_table}.#{db_field} AS decimal(60,3)) <= #{value.first.to_f})"
          else
            sql = "#{db_table}.#{db_field} <= #{value.first.to_f}"
          end
        end
      when "><"
        if [:date, :date_past].include?(query_given.type_for(field)) || field.eql?("created_at")
          sql = date_clause(db_table, db_field, (Date.parse(value[0]) rescue nil), (Date.parse(value[1]) rescue nil))
        else
          if is_custom_filter
            sql = "(#{db_table}.#{db_field} <> '' AND CAST(#{db_table}.#{db_field} AS decimal(60,3)) BETWEEN #{value[0].to_f} AND #{value[1].to_f})"
          else
            sql = "#{db_table}.#{db_field} BETWEEN #{value[0].to_f} AND #{value[1].to_f}"
          end
        end

      when ">t-"
        sql = relative_date_clause(db_table, db_field, - value.first.to_i, 0)
      when "<t-"
        sql = relative_date_clause(db_table, db_field, nil, - value.first.to_i)
      when "t-"
        sql = relative_date_clause(db_table, db_field, - value.first.to_i, - value.first.to_i)
      when ">t+"
        sql = relative_date_clause(db_table, db_field, value.first.to_i, nil)
      when "<t+"
        sql = relative_date_clause(db_table, db_field, 0, value.first.to_i)
      when "t+"
        sql = relative_date_clause(db_table, db_field, value.first.to_i, value.first.to_i)
      when "t"
        sql = relative_date_clause(db_table, db_field, 0, 0)
      when "w"
        first_day_of_week = l(:general_first_day_of_week).to_i
        day_of_week = Date.today.cwday
        days_ago = (day_of_week >= first_day_of_week ? day_of_week - first_day_of_week : day_of_week + 7 - first_day_of_week)
        sql = relative_date_clause(db_table, db_field, - days_ago, - days_ago + 6)
      when "~"
        sql = "LOWER(#{db_table}.#{db_field}) LIKE '%#{ActiveRecord::Base.connection.quote_string(value.first.to_s.downcase)}%'"
      when "!~"
        sql = "LOWER(#{db_table}.#{db_field}) NOT LIKE '%#{ActiveRecord::Base.connection.quote_string(value.first.to_s.downcase)}%'"
      else
        #raise "Unknown query operator #{operator}"
    end

    return sql
  end

  def date_clause(table, field, from, to)
    time = Time.new
    s = []
    if from
      from_yesterday = from - 1
      from_yesterday_time = Time.local(from_yesterday.year, from_yesterday.month, from_yesterday.day)
      if time.zone == :utc
        from_yesterday_time = from_yesterday_time.utc
      end
      s << ("#{table}.#{field} > '%s'" % [ActiveRecord::Base.connection.quoted_date(from_yesterday_time.end_of_day)])
    end
    if to
      to_time = Time.local(to.year, to.month, to.day)
      if time.zone == :utc
        to_time = to_time.utc
      end
      s << ("#{table}.#{field} <= '%s'" % [ActiveRecord::Base.connection.quoted_date(to_time.end_of_day)])
    end
    s.join(' AND ')
  end

  def relative_date_clause(table, field, days_from, days_to)
    date_clause(table, field, (days_from ? Date.today + days_from : nil), (days_to ? Date.today + days_to : nil))
  end
end
