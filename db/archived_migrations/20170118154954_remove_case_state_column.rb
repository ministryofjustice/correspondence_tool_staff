class RemoveCaseStateColumn < ActiveRecord::Migration[5.0]
  # rubocop:disable Rails/ReversibleMigration
  def change
    remove_column :cases, :state
  end
  # rubocop:enable Rails/ReversibleMigration
end
