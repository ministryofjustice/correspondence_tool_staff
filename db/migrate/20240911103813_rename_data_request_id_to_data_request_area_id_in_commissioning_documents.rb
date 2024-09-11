class RenameDataRequestIdToDataRequestAreaIdInCommissioningDocuments < ActiveRecord::Migration[7.1]
  def up
    rename_column :commissioning_documents, :data_request_id, :data_request_area_id
  end

  def down
    rename_column :commissioning_documents, :data_request_area_id, :data_request_id
  end
end
