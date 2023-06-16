class AddParentIdToSearchQueries < ActiveRecord::Migration[5.0]
  create_enum :search_query_type, "search", "filter"

  def change
    add_column :search_queries, :parent_id, :integer
    add_column :search_queries, :query_type, :search_query_type, null: false, default: :search
    add_column :search_queries, :filter_type, :string
  end
end
