class AddRequestTypesToDataRequests < ActiveRecord::Migration[7.1]
  # rubocop:disable Rails/ReversibleMigration
  def change
    execute <<~SQL
      ALTER TYPE request_types ADD VALUE 'education';
      ALTER TYPE request_types ADD VALUE 'oasys_arns';
      ALTER TYPE request_types ADD VALUE 'dps_security';
      ALTER TYPE request_types ADD VALUE 'hpa';
    SQL
  end
  # rubocop:enable Rails/ReversibleMigration
end
