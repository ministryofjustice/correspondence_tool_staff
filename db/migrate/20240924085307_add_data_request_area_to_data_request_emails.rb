class AddDataRequestAreaToDataRequestEmails < ActiveRecord::Migration[7.1]
  def up
    add_column :data_request_emails, :data_request_area_id, :bigint
  end

  def down
    remove_column :data_request_emails, :data_request_area_id
  end
end
