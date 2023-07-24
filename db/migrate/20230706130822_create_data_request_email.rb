class CreateDataRequestEmail < ActiveRecord::Migration[6.1]
  def change
    create_table :data_request_emails do |t|
      t.references :data_request
      t.column :email_type, :integer, default: 0
      t.string :email_address
      t.string :notify_id
      t.string :status
      t.timestamps
    end
  end
end
