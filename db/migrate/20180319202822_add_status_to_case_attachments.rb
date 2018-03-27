class AddStatusToCaseAttachments < ActiveRecord::Migration[5.0]
  def change
    add_column :case_attachments, :state, :string,
               null: false,
               default: 'unprocessed'
  end
end
