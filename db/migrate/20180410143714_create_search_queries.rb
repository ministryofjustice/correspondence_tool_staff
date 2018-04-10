class CreateSearchQueries < ActiveRecord::Migration[5.0]
  def change
    create_table :search_queries do |t|
      t.string :uuid, null: false
      t.string :query, null: false
      t.integer :num_results, null: false
      t.integer :num_clicks, null: false, default: 0
    end

    add_index :search_queries, :uuid, unique: true, name: 'index_search_queries_uuid'
  end
end
