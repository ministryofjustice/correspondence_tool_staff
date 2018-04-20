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

  acts_as_tree

  def self.by_query_hash!(query_hash)
    self.find_by!(query_hash: query_hash)
  end

  def self.by_query_hash_with_ancestors!(query_hash)
    record = by_query_hash!(query_hash)
    record.ancestors.reverse + [record]
  end

  def self.new_from_search_service(case_search_service)
    if case_search_service.filter?
      new_filter_record(case_search_service)
    else
      new_search_record(case_search_service)
    end
  end

  def self.create_from_search_service(case_search_service)
    new_from_search_service(case_search_service).save!
  end

  def self.new_search_record(service)
    search_query = SearchQuery.find_by(query_hash: service.query_hash)
    if search_query.nil?
      self.new(
              query_type:     'search',
              query_hash:     service.query_hash,
              user_id:        service.current_user.id,
              query:          "{\"search\": {\"query\": \"#{service.query}\"}}",
              parent_id:      parent_search_query_id(service),
              num_results:    service.unpaginated_result_set.size
      )
    else
      search_query
    end
  end

  def self.new_filter_record(service)
    search_query = SearchQuery.find_by(query_hash: service.query_hash)
    if search_query.nil?
      self.new(
              query_type:     'filter',
              filter_type:    service.filter_type,
              query_hash:     service.query_hash,
              user_id:        service.current_user.id,
              parent_id:      parent_search_query_id(service),
              query:          "{\"filter\": {\"query\": \"#{service.query}\"}}",
              num_results:    service.unpaginated_result_set.size
      )
    else
      search_query
    end
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

  def search_query
    query['search']['query']
  end
end
