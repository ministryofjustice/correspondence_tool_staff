class ChangeCommissioningDocumentSentToSentAt < ActiveRecord::Migration[7.2]
  def up
    add_column :commissioning_documents, :sent_at, :datetime

    CommissioningDocument.where(sent: true).find_each do |document|
      document.update_attribute(:sent_at, document.updated_at) # rubocop:disable Rails/SkipsModelValidations
    end

    remove_column :commissioning_documents, :sent
  end

  def down
    add_column :commissioning_documents, :sent, :boolean, default: false

    CommissioningDocument.where.not(sent_at: nil).find_each do |document|
      document.update_attribute(:sent, true) # rubocop:disable Rails/SkipsModelValidations
    end

    remove_column :commissioning_documents, :sent_at
  end
end
