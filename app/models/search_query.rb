# == Schema Information
#
# Table name: search_queries
#
#  id          :integer          not null, primary key
#  uuid        :string           not null
#  query       :string           not null
#  num_results :integer          not null
#  num_clicks  :integer          default(0), not null
#

class SearchQuery < ApplicationRecord


  def self.create_from_search_service(case_search_service)
    create!(
      uuid:           case_search_service.uuid,
      query:          case_search_service.query,
      num_results:    case_search_service.result_set.size
    )
  end

end
