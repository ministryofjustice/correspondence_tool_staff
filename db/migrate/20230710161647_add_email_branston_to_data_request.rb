class AddEmailBranstonToDataRequest < ActiveRecord::Migration[6.1]
  def change
    add_column :data_requests, :email_branston_archives, :boolean, default: false
  end
end
