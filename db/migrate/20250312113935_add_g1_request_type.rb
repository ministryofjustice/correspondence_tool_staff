class AddG1RequestType < ActiveRecord::Migration[7.2]
  # rubocop:disable Rails/ReversibleMigration
  def change
    execute <<~SQL
      ALTER TYPE request_types ADD VALUE 'g1_security';
    SQL

    DataRequestArea.where(data_request_area_type: "security").find_each do |dra|
      dra.update!(data_request_area_type: "dps_sensitive")
    end
  end
  # rubocop:enable Rails/ReversibleMigration
end
