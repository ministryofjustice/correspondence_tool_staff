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

FactoryGirl.define do
  factory :search_query do
    query_hash { (0..10).map { ('a'..'z').to_a[rand(26)] }.join }
    user_id 3
    query 'Winnie the Pooh'
    query_type 'search'
    parent_id nil
    num_results 33
    num_clicks 0
    highest_position nil
  end

  trait :filter do
    query_type 'filter'
  end

  trait :clicked do
    num_clicks 1
    highest_position 3
  end
end
