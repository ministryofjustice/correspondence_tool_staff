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
                 filter_sensitivity: [:string, array: true, default: []],
                 filter_case_type: [:string, array: true, default: []],
                 filter_status: [:string, array: true, default: []]
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

  def filter_classes
    [
      CaseTypeFilter,
      CaseStatusFilter,
    ]
  end

  def sensitivity_settings
    {
      'non-trigger' => 'Non-trigger',
      'trigger'     => 'Trigger',
    }
  end

  def type_settings
    {
      'foi-standard' => 'FOI - Standard',
      'foi-ir-compliance' => 'FOI - Internal review for compliance',
      'foi-ir-timeliness' => 'FOI - Internal review for timeliness',
    }
  end

  delegate :available_statuses, to: CaseStatusFilter

  def results
    results = Case::BasePolicy::Scope.new(User.find(user_id), Case::Base.all).for_view_only
    results = results.search(search_text)
    filter_classes.reduce(results) do |result, filter_class|
      filter_class.new(self, result).call
    end
  end
end
