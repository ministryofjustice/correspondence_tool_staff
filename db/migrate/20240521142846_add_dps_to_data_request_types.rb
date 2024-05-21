class AddDpsToDataRequestTypes < ActiveRecord::Migration[7.1]
  # rubocop:disable Rails/ReversibleMigration
  def change
    execute <<~SQL
      ALTER TYPE request_types ADD VALUE 'dps';
    SQL
  end
  # rubocop:disable Rails/ReversibleMigration
end
