class RemoveDefaultType < ActiveRecord::Migration[5.0]
  # rubocop:disable Rails/ReversibleMigration
  def change
    change_column_default(:cases, :type, nil)
  end
  # rubocop:enable Rails/ReversibleMigration
end
