class DropQueryHashFromSearchQueries < ActiveRecord::Migration[5.0]
  # rubocop:disable Rails/ReversibleMigration
  def change
    remove_column :search_queries, :query_hash
  end
  # rubocop:enable Rails/ReversibleMigration
end
