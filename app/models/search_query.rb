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

  attr_accessor :business_unit_name_filter

  FILTER_CLASSES =     [
    CaseTypeFilter,
    CaseStatusFilter,
    ExemptionFilter,
    AssignedBusinessUnitFilter,
    ExternalDeadlineFilter
  ]

  belongs_to :user
  belongs_to :parent, class_name: 'SearchQuery'
  has_many   :children, class_name: 'SearchQuery'

  enum query_type: {
      search: 'search',
      filter: 'filter'
  }

  jsonb_accessor :query,
                 search_text: :string,
                 filter_type: :string,
                 filter_assigned_to_ids: [:integer, array: true, default: []],
                 external_deadline_from: :date,
                 external_deadline_to: :date,
                 filter_sensitivity: [:string, array: true, default: []],
                 filter_case_type: [:string, array: true, default: []],
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

  def update_for_click(position)
    self.num_clicks += 1
    if self.highest_position.nil? || self.highest_position > position
      self.highest_position = position
    end
    save!
  end



  delegate :available_sensitivities, to: CaseTypeFilter
  delegate :available_case_types, to: CaseTypeFilter
  delegate :available_statuses, to: CaseStatusFilter
  delegate :available_exemptions, to: ExemptionFilter
  delegate :available_common_exemptions, to: ExemptionFilter
  delegate :responding_business_units, to: AssignedBusinessUnitFilter
  delegate :available_deadlines, to: ExternalDeadlineFilter

  def results
    results = Case::BasePolicy::Scope.new(User.find(user_id), Case::Base.all).for_view_only
    results = results.search(search_text)
    FILTER_CLASSES.reduce(results) do |result, filter_class|
      filter_class.new(self, result).call
    end
  end
end
