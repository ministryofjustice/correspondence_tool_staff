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

  validates_presence_of :search_text, if: :search?

  enum query_type: {
      search: 'search',
      filter: 'filter',
      list: 'list'
  }

  jsonb_accessor :query,
                 search_text: [:string, default: nil],
                 list_path: [:string, default: nil],
                 filter_assigned_to_ids: [:integer, array: true, default: []],
                 external_deadline_from: :date,
                 external_deadline_to: :date,
                 filter_sensitivity: [:string, array: true, default: []],
                 filter_case_type: [:string, array: true, default: []],
                 filter_open_case_status: [:string, array: true, default: []],
                 filter_timeliness: [:string, array: true, default: []],
                 exemption_ids: [:integer, array: true, default: []],
                 common_exemption_ids: [:integer, array: true, default: []],
                 filter_status: [:string, array: true, default: []]

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
    @filter_attributes ||= FILTER_CLASSES.collect_concat do |filter_class|
      filter_class.filter_attributes
    end
  end

  def self.query_attributes
    @query_attributes ||= self.filter_attributes + [
      :search_text,
      :list_path,
    ]
  end

  def update_for_click(position)
    self.num_clicks += 1
    if self.highest_position.nil? || self.highest_position > position
      self.highest_position = position
    end
    save!
  end

  # Find of create a SearchQuery from the given <tt>query_params</tt>
  #
  # This doesn't follow the usual semantics of find or create because:
  #
  # a) the search query params coming are usually only partially complete, e.g.
  #    when applying filters only a single set of filter params are sent in at
  #    a time so we look to our parent to get a complete picture of the filters
  # b) a search query can match within the same day so created_at time has to
  #    be taken into consideration
  # c) we're searching using the JSON query field as well as other columns
  def self.find_or_create(query_params)
    if query_params.key? :parent_id
      parent = find(query_params[:parent_id])
      existing_query_params = ActionController::Parameters.new(
        parent.slice(*query_attributes)
      ).permit!
    else
      existing_query_params = ActionController::Parameters.new(
        SearchQuery.new.query
      ).permit!
    end
    merged_params = existing_query_params.merge(query_params)

    params_to_match_on = merged_params.slice(*query_attributes).to_h
    search_query = SearchQuery
                     .where(user_id: merged_params[:user_id],
                            query_type: merged_params[:query_type])
                     .where('created_at >= ? AND created_at < ?',
                            Date.today, Date.tomorrow)
                     .where('query = ?', params_to_match_on.to_json)
                     .first
    if search_query.nil?
      search_query = SearchQuery.create(merged_params)
    end
    search_query
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

  def filter?
    self.class.filter_attributes.any? do |attr|
      query[attr.to_s].present?
    end
  end

  private

  def perform_filters(cases)
    applied_filters.reduce(cases) do |result, filter_class|
      filter_class.new(self, result).call
    end
  end
end
