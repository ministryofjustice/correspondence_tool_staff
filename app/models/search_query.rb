# == Schema Information
#
# Table name: search_queries
#
#  id               :integer          not null, primary key
#  user_id          :integer          not null
#  query            :jsonb            not null
#  num_results      :integer          default(0), not null
#  num_clicks       :integer          default(0), not null
#  highest_position :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  parent_id        :integer
#  query_type       :enum             default("search"), not null
#  filter_type      :string
#

class SearchQuery < ApplicationRecord
  include ActiveRecord::Store

  include SearchHelper

  FILTER_CLASSES_MAP = {
    "all_cases" => [
      CaseFilter::OpenCaseStatusFilter,
      CaseFilter::CaseTypeFilter,
      CaseFilter::CaseTriggerFlagFilter,
      CaseFilter::TimelinessFilter,
      CaseFilter::ExternalDeadlineFilter,
      CaseFilter::InternalDeadlineFilter,
      CaseFilter::CaseHighProfileFilter,
      CaseFilter::CaseComplaintTypeFilter,
      CaseFilter::CaseComplaintSubtypeFilter,
      CaseFilter::CaseComplaintPriorityFilter,
      CaseFilter::CaseworkerFilter,
    ],
    "closed" => [
      CaseFilter::ReceivedDateFilter,
      CaseFilter::DateRespondedFilter,
      CaseFilter::CaseTypeFilter,
      CaseFilter::ExemptionFilter,
      CaseFilter::CaseHighProfileFilter,
      CaseFilter::CaseComplaintTypeFilter,
      CaseFilter::CaseComplaintSubtypeFilter,
      CaseFilter::CaseComplaintPriorityFilter,
      CaseFilter::CasePartialCaseFlagFilter,
    ],
    "my_cases" => [
      CaseFilter::OpenCaseStatusFilter,
      CaseFilter::CaseComplaintTypeFilter,
      CaseFilter::CaseComplaintSubtypeFilter,
      CaseFilter::CaseComplaintPriorityFilter,
    ],
    "search_cases" => [
      CaseFilter::CaseStatusFilter,
      CaseFilter::OpenCaseStatusFilter,
      CaseFilter::CaseTypeFilter,
      CaseFilter::CaseTriggerFlagFilter,
      CaseFilter::TimelinessFilter,
      CaseFilter::ExternalDeadlineFilter,
      CaseFilter::ExemptionFilter,
      CaseFilter::CaseHighProfileFilter,
      CaseFilter::CaseComplaintTypeFilter,
      CaseFilter::CaseComplaintSubtypeFilter,
      CaseFilter::CaseComplaintPriorityFilter,
      CaseFilter::CasePartialCaseFlagFilter,
    ],
    "retention_pending_removal" => [
      CaseFilter::CaseRetentionDeadlineFilter,
      CaseFilter::CaseRetentionStateFilter,
    ],
    "retention_ready_for_removal" => [
      CaseFilter::CaseRetentionDeadlineFilter,
    ],
  }.freeze

  attr_accessor :business_unit_name_filter

  belongs_to :user
  belongs_to :parent, class_name: "SearchQuery"
  has_many   :children, class_name: "SearchQuery"

  validates :search_text, presence: { if: :search_query_type? }

  enum query_type: {
    search: "search",
    filter: "filter",
    list: "list",
  }, _suffix: true

  # Add all those properties withn query jsonb fields
  @@typed_filter_fields = { search_text: [:string, { default: nil }], list_path: [:string, { default: nil }] }
  FILTER_CLASSES_MAP.to_hash.values.flatten.uniq.each do |filter_class|
    filter_class.filter_fields(@@typed_filter_fields)
  end
  jsonb_accessor(:query, **@@typed_filter_fields)

  # Define the list of date fields
  GOV_UK_DATE_FIELDS = CaseFilter::ReceivedDateFilter.date_fields +
    CaseFilter::DateRespondedFilter.date_fields +
    CaseFilter::ExternalDeadlineFilter.date_fields +
    CaseFilter::InternalDeadlineFilter.date_fields +
    CaseFilter::CaseRetentionDeadlineFilter.date_fields

  acts_as_gov_uk_date(*GOV_UK_DATE_FIELDS)

  acts_as_tree

  def self.parent_search_query_id(case_search_service)
    if case_search_service.child?
      by_query_hash!(case_search_service.parent_hash).id
    end
  end

  def self.filter_classes
    FILTER_CLASSES_MAP.to_hash.values.flatten.uniq
  end

  def self.filter_attributes
    @filter_attributes ||= filter_classes.collect_concat(&:filter_attributes)
  end

  def self.query_attributes
    @query_attributes ||= filter_attributes + %i[
      search_text
      list_path
    ]
  end

  def update_for_click(position)
    self.num_clicks += 1
    if highest_position.nil? || highest_position > position
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
    if query_params[:parent_id].present?
      parent = find(query_params[:parent_id])
      existing_query_params = ActionController::Parameters.new(
        parent.slice(*query_attributes),
      ).permit!
    else
      existing_query_params = ActionController::Parameters.new(
        SearchQuery.new.query,
      ).permit!
    end
    merged_params = existing_query_params.merge(query_params)

    params_to_match_on = merged_params.slice(*query_attributes).to_h
    search_query = SearchQuery
                     .where(user_id: merged_params[:user_id],
                            query_type: merged_params[:query_type])
                     .where("created_at >= ? AND created_at < ?",
                            Time.zone.today, Date.tomorrow)
                     .where("query = ?", params_to_match_on.to_json)
                     .first
    if search_query.nil?
      search_query = SearchQuery.create!(merged_params)
    end
    search_query
  end

  def results(cases_list = nil, search_order_choice = nil)
    if root.query_type == "search"
      cases_list ||= Pundit.policy_scope(user, Case::Base.all)
      cases_list = cases_list.__send__(SearchHelper.get_order_option(search_order_choice.to_s), search_text)
    elsif cases_list.nil?
      raise ArgumentError, "cannot perform filters without list of cases"
    elsif search_order_choice.present?
      order_fields = SearchHelper.get_order_fields(search_order_choice)
      cases_list = cases_list.order(order_fields)
    end

    perform_filters(cases_list)
  end

  def filter_crumbs
    filter_crumbs = []
    filters = applied_filters.map do |filter_class|
      filter_class.new(self, user, Case::Base.none)
    end
    filters.each { |filter| filter_crumbs += filter.crumbs }
    filter_crumbs
  end

  def params_without_filters
    query.except(*self.class.filter_attributes.map(&:to_s))
  end

  def applied_filters
    self.class.filter_classes.select do |filter_class|
      filter = filter_class.new(self, user, Case::Base.none)
      filter.applied?
    end
  end

  def filter?
    self.class.filter_attributes.any? do |attr|
      query[attr.to_s].present?
    end
  end

  def available_filters(user, scope_type)
    collected_filters = []
    if FILTER_CLASSES_MAP.to_hash.key?(scope_type)
      FILTER_CLASSES_MAP[scope_type].each do |filter_class|
        filter_class_instance = filter_class.new(self, user, Case::Base.none)
        collected_filters << filter_class_instance if filter_class_instance.is_permitted_for_user?
      end
    end
    collected_filters
  end

private

  def perform_filters(cases)
    applied_filters.reduce(cases) do |result, filter_class|
      filter_class.new(self, user, result).call
    end
  end
end
