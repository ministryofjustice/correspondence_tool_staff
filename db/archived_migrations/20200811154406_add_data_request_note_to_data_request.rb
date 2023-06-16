class AddDataRequestNoteToDataRequest < ActiveRecord::Migration[5.2]
  def change
    add_column :data_requests, :data_request_note, :text, null: false, default: ""
  end
end
