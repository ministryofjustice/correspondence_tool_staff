# == Schema Information
#
# Table name: search_queries
#
#  id               :integer          not null, primary key
#  query_hash       :string           not null
#  user_id          :integer          not null
#  query            :string           not null
#  num_results      :integer          not null
#  num_clicks       :integer          default(0), not null
#  highest_position :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class SearchQuery < ApplicationRecord

  belongs_to :user


  def self.create_from_search_service(case_search_service)
    if SearchQuery.find_by(query_hash: case_search_service.query_hash).nil?
      create!(
          query_hash:     case_search_service.query_hash,
          user_id:        case_search_service.current_user.id,
          query:          case_search_service.query,
          num_results:    case_search_service.unpaginated_result_set.size
      )
    end
  end


  def self.update_for_click(params, flash)
    if params[:hash] == flash[:query_hash]
      record_click(params)
    end
  end



  def self.record_click(params)
    record = SearchQuery.find_by(query_hash: params[:hash])
    unless record.nil?
      record.num_clicks +=1
      if record.highest_position.nil? || record.highest_position > params[:pos].to_i
        record.highest_position = params[:pos].to_i
      end
      record.save!
    end
  end

  private_class_method :record_click

end
