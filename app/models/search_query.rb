# == Schema Information
#
# Table name: search_queries
#
#  id               :integer          not null, primary key
#  user_id          :integer          not null
#  query            :jsonb            not null
#  num_results      :integer          not null
#  num_clicks       :integer          default(0), not null
#  highest_position :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  parent_id        :integer
#  query_type       :enum             default("search"), not null
#  filter_type      :string
#

class SearchQuery < ApplicationRecord
  FILTER_CLASSES = [
    CaseTypeFilter,
    TimelinessFilter,
    CaseStatusFilter,
    OpenCaseStatusFilter,
    ExternalDeadlineFilter,
    AssignedBusinessUnitFilter,
    ExemptionFilter,
  ].freeze

  attr_accessor :business_unit_name_filter

  belongs_to :user
  belongs_to :parent, class_name: 'SearchQuery'
  has_many   :children, class_name: 'SearchQuery'

  enum query_type: {
      search: 'search',
      filter: 'filter',
      list: 'list'
  }

  jsonb_accessor :query,
                 search_text: :string,
                 filter_type: :string,
                 filter_assigned_to_ids: [:integer, array: true, default: []],
                 external_deadline_from: :date,
                 external_deadline_to: :date,
                 filter_sensitivity: [:string, array: true, default: []],
                 filter_case_type: [:string, array: true, default: []],
                 filter_open_case_status: [:string, array: true, default: []],
                 filter_timeliness: [:string, array: true, default: []],
                 exemption_ids: [:integer, array: true, default: []],
                 common_exemption_ids: [:integer, array: true, default: []],
                 filter_status: [:string, array: true, default: []],
                 list_path: [:string, default: '']

  acts_as_gov_uk_date :external_deadline_from, :external_deadline_to

  acts_as_tree

  def self.parent_search_query_id(case_search_service)
    if case_search_service.child?
      self.by_query_hash!(case_search_service.parent_hash).id
    else
      nil
    end
  end

  def self.filter_attributes
    FILTER_CLASSES.collect_concat do |filter_class|
      filter_class.filter_attributes
    end
  end

  def self.query_attributes
    [:search_text, :list_path] + self.filter_attributes
  end

  def update_for_click(position)
    self.num_clicks += 1
    if self.highest_position.nil? || self.highest_position > position
      self.highest_position = position
    end
    save!
  end

  def self.record_list(user, path)
    self.create!(user_id: user.id,
                 list_path: path,
                 query_type: :list,
                 num_results: 0)

  end

  delegate :available_sensitivities, to: CaseTypeFilter
  delegate :available_case_types, to: CaseTypeFilter
  delegate :available_statuses, to: CaseStatusFilter
  delegate :available_exemptions, to: ExemptionFilter
  delegate :available_common_exemptions, to: ExemptionFilter
  delegate :responding_business_units, to: AssignedBusinessUnitFilter
  delegate :available_deadlines, to: ExternalDeadlineFilter
  delegate :available_open_case_statuses, to: OpenCaseStatusFilter
  delegate :available_timeliness, to: TimelinessFilter

  def results(cases_list = nil)
    if root.query_type == 'search'
      cases_list ||= Case::BasePolicy::Scope
                       .new(User.find(user_id), Case::Base.all)
                       .for_view_only
      cases_list = cases_list.search(search_text)
    elsif cases_list.nil?
      raise ArgumentError.new("cannot perform filters without list of cases")
    end

    perform_filters(cases_list)
  end

  def filter_crumbs
    filter_crumbs = []
    applied_filters.map do |filter_class|
      filter_class.new(self, Case::Base.none)
    end.each do |filter|
      filter_crumbs += filter.crumbs
    end
    filter_crumbs
  end

  def params_without_filters
    query.except(*(self.class.filter_attributes.map(&:to_s)))
  end

  def applied_filters
    FILTER_CLASSES.select do |filter_class|
      filter = filter_class.new(self, Case::Base.none)
      filter.applied?
    end
  end

  private

  def perform_filters(cases)
    applied_filters.reduce(cases) do |result, filter_class|
      filter_class.new(self, result).call
    end
  end
end
