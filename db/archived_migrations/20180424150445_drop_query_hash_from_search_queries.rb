class DropQueryHashFromSearchQueries < ActiveRecord::Migration[5.0]
  def change
    remove_column :search_queries, :query_hash
  end
end
