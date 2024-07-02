class AddCctvBwcfToDataRequestTypes < ActiveRecord::Migration[7.1]
  # rubocop:disable Rails/ReversibleMigration
  def change
    execute <<~SQL
      ALTER TYPE request_types ADD VALUE 'cctv';
      ALTER TYPE request_types ADD VALUE 'bwcf';
    SQL
  end
  # rubocop:enable Rails/ReversibleMigration
end
