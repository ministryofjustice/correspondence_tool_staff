class AddSecurityAndOtherDepartmentRequestTypesToDataRequests < ActiveRecord::Migration[7.1]
  # rubocop:disable Rails/ReversibleMigration
  def change
    execute <<~SQL
      ALTER TYPE request_types ADD VALUE 'g2_security';
      ALTER TYPE request_types ADD VALUE 'g3_security';
      ALTER TYPE request_types ADD VALUE 'other_department';
    SQL
  end
  # rubocop:enable Rails/ReversibleMigration
end
