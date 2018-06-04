class AddDefaultForSearchQueriesNumResults < ActiveRecord::Migration[5.0]
  def up
    change_column :search_queries, :num_results, :integer, default: 0
  end

  def down
    change_column :search_queries, :num_results, :integer
  end
end
