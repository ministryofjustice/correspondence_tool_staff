class RenameDataRequestNoteToRequestTypeNoteForDataRequest < ActiveRecord::Migration[5.2]
  def change
    rename_column :data_requests, :data_request_note, :request_type_note
  end
end
