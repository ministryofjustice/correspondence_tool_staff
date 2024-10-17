class AddSecurityAndOtherDepartmentToDataRequestAreas < ActiveRecord::Migration[7.1]
  # rubocop:disable Rails/ReversibleMigration
  def change
    execute <<~SQL
      ALTER TYPE data_request_area_types ADD VALUE 'security';
      ALTER TYPE data_request_area_types ADD VALUE 'other_department';
    SQL
  end
  # rubocop:enable Rails/ReversibleMigration
end
