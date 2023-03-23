class AddContactIdToDataRequest < ActiveRecord::Migration[6.1]
  def change
    add_reference :data_requests, :contact, foreign_key: true, nil: true
  end
end
