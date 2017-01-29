class CreateCaseAttachments < ActiveRecord::Migration[5.0]
  def up
    create_enum :attachment_type, 'response'

    create_table :case_attachments do |t|
      t.belongs_to :case
      t.column :type, :attachment_type
      t.string :url

      t.timestamps
    end
  end

  def down
    drop_table :case_attachments
    drop_enum :attachment_type
  end
end
