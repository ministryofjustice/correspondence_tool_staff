class AddDpsSensitiveRequestType < ActiveRecord::Migration[7.2]
  # rubocop:disable Rails/ReversibleMigration
  def change
    execute <<~SQL
      ALTER TYPE request_types ADD VALUE 'g1_security';
      ALTER TYPE data_request_area_type ADD VALUE 'dps_sensitive';
    SQL
  end
  # rubocop:enable Rails/ReversibleMigration
end
