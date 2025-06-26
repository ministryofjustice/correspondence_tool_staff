class AddBodyScanDataType < ActiveRecord::Migration[7.2]
  # rubocop:disable Rails/ReversibleMigration
  def change
    execute <<~SQL
      ALTER TYPE request_types ADD VALUE 'body_scans';
    SQL
  end
  # rubocop:enable Rails/ReversibleMigration
end
