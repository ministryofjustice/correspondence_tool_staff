class AddAttachmentIdToCommissioningDocument < ActiveRecord::Migration[6.1]
  def change
    add_reference :commissioning_documents, :attachment, null: true
  end
end
