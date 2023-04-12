class RenameContactEmail < ActiveRecord::Migration[6.1]
  def up
    rename_column :contacts, :email, :data_request_emails
  end

  def down
    rename_column :contacts, :data_request_emails, :email
  end
end
