FactoryGirl.define do
  factory :search_query do
    query_hash 'XYZ'
    user_id 3
    query 'Winnie the Pooh'
    num_results 33
    num_clicks 0
    highest_position nil

  end

  trait :clicked do
    num_clicks 1
    highest_position 3
  end
end
