class AddStandardToTemplateNames < ActiveRecord::Migration[7.1]
  # rubocop:disable Rails/ReversibleMigration
  def change
    execute <<~SQL
      ALTER TYPE template_name ADD VALUE 'standard';
    SQL
  end
  # rubocop:enable Rails/ReversibleMigration
end
