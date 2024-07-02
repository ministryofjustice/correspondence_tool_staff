class AddCctvBwcfToDataRequestTypes < ActiveRecord::Migration[7.1]
  # rubocop:disable Rails/ReversibleMigration
  def change
    execute <<~SQL
      ALTER TYPE request_types ADD VALUE 'cctv1';
      ALTER TYPE request_types ADD VALUE 'bwcf1';
    SQL
  end
  # rubocop:enable Rails/ReversibleMigration
end
