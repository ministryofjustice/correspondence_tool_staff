class AddAttachmentType < ActiveRecord::Migration[6.1]
  # rubocop:disable Rails/ReversibleMigration
  def change
    execute <<~SQL
      ALTER TYPE attachment_type ADD VALUE 'commissioning_document';
    SQL
  end
  # rubocop:enable Rails/ReversibleMigration
end
