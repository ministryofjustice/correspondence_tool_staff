class AddAttachmentType < ActiveRecord::Migration[6.1]
  def change
    execute <<~SQL
      ALTER TYPE attachment_type ADD VALUE 'commissioning_document';
    SQL
  end
end
