class AddPreviewKeyToCaseAttachments < ActiveRecord::Migration[5.0]
  def change
    add_column :case_attachments, :preview_key, :string
  end
end
