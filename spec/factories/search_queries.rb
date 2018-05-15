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

FactoryGirl.define do
  factory :search_query do
    user_id { find_or_create(:manager).id }
    # query({ search_text: 'Winnie the Pooh' })
    search_text 'Winnie the Pooh'
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

  trait :list do
    search_text nil
    query_type 'list'
    list_path '/cases/open/in_time'
    list_params ActiveSupport::HashWithIndifferentAccess.new({ controller: 'cases', action: 'open_cases', tab: 'in_time' }).to_yaml
  end

  trait :filtered_list do
    search_text nil
    query_type 'filter'
    list_path '/cases/open/in_time'
    list_params ActiveSupport::HashWithIndifferentAccess.new({ controller: 'cases', action: 'open_cases', tab: 'in_time' }).to_yaml
    filter_case_type ['foi-ir-compliance']
    filter_sensitivity []
  end
end
