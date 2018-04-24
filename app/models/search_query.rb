# == Schema Information
#
# Table name: search_queries
#
#  id               :integer          not null, primary key
#  user_id          :integer          not null
#  parent_id        :integer
#  query_type       :enum             default("search"), not null
#  filter_type      :string
#  query            :string           not null
#  query_hash       :string           not null
#  num_results      :integer          not null
#  num_clicks       :integer          default(0), not null
#  highest_position :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
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
                 filter_case_type: [:string, array: true, default: []]
  acts_as_tree

  def self.by_query_hash!(query_hash)
    self.find_by!(query_hash: query_hash)
  end

  def self.by_query_hash_with_ancestors!(query_hash)
    record = by_query_hash!(query_hash)
    record.ancestors.reverse + [record]
  end

  def self.update_for_click(query_hash, position)
    record = SearchQuery.find_by(query_hash: query_hash)
    unless record.nil?
      record.num_clicks += 1
      if record.highest_position.nil? || record.highest_position > position
        record.highest_position = position
      end
      record.save!
    end
  end

  def self.parent_search_query_id(case_search_service)
    if case_search_service.child?
      self.by_query_hash!(case_search_service.parent_hash).id
    else
      nil
    end
  end

  def results
    if parent.present?
      results = parent.results
    else
      results = Pundit.policy_scope!(User.find(user_id), Case::Base)
    end

    if search?
      results.search(search_text)
    elsif filter?
      filter_module = "#{filter_type.camelize}Filter".constantize
      filter_module.call(self, results)
    else
      RuntimeError.new("Unknown search query type #{query_type}")
    end
  end

  def inherited_attribute_value(attribute)
    if self.__send__(attribute).present?
      self.__send__(attribute)
    else
      parent.inherited_attribute_value(attribute)
    end
  end
end
