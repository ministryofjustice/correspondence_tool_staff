class AddDataRequestAreaToCommissioningDocuments < ActiveRecord::Migration[7.1]
  def up
    add_column :commissioning_documents, :data_request_area_id, :bigint
  end

  def down
    remove_column :commissioning_documents, :data_request_area_id
  end
end
