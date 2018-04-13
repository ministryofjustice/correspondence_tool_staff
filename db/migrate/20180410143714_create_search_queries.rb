class CreateSearchQueries < ActiveRecord::Migration[5.0]
  def change

    create_enum :search_query_type, 'search', 'filter'

    create_table :search_queries do |t|
      t.integer           :user_id, null: false
      t.integer           :parent_id
      t.column            :query_type, :search_query_type, null: false, default: :search
      t.string            :filter_type
      t.string            :query, null: false
      t.string            :query_hash, null: false
      t.integer           :num_results, null: false
      t.integer           :num_clicks, null: false, default: 0
      t.integer           :highest_position, null: true

      t.timestamps
    end

    add_index :search_queries, :query_hash, unique: true, name: 'index_search_queries_uuid'
  end
end
