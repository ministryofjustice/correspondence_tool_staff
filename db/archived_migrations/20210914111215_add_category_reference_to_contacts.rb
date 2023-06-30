class AddCategoryReferenceToContacts < ActiveRecord::Migration[5.2]
  # rubocop:disable Rails/ReversibleMigration
  def change
    remove_column :contacts, :contact_type
    add_reference :contacts, :contact_type, foreign_key: { to_table: :category_references }, index: true
  end
  # rubocop:enable Rails/ReversibleMigration
end
