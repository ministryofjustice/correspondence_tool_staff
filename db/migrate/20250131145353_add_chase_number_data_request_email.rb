class AddChaseNumberDataRequestEmail < ActiveRecord::Migration[7.2]
  def change
    add_column :data_request_emails, :chase_number, :integer
  end
end
