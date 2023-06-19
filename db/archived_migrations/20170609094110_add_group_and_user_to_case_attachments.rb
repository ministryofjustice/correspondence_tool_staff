class AddGroupAndUserToCaseAttachments < ActiveRecord::Migration[5.0]
  def up
    add_column :case_attachments, :upload_group, :string
    add_column :case_attachments, :user_id, :integer

    require Rails.root.join("db/seeders/case_attachment_upload_group_seeder")
    CaseAttachmentUploadGroupSeeder.new.run
  end

  def down
    remove_column :case_attachments, :upload_group
    remove_column :case_attachments, :user_id
  end
end
