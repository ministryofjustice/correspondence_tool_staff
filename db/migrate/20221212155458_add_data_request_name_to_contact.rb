class AddDataRequestNameToContact < ActiveRecord::Migration[6.1]
  def change
    add_column :contacts, :data_request_name, :string
  end
end
