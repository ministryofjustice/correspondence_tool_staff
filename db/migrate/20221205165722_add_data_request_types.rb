class AddDataRequestTypes < ActiveRecord::Migration[6.1]
  # rubocop:disable Rails/ReversibleMigration
  def change
    execute <<~SQL
      ALTER TYPE request_types ADD VALUE 'cross_borders';
      ALTER TYPE request_types ADD VALUE 'cat_a';
      ALTER TYPE request_types ADD VALUE 'ndelius_contact_lists';
    SQL
  end
  # rubocop:enable Rails/ReversibleMigration
end
