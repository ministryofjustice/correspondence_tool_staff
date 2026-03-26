class AddProcessedToPersonalInformationRequests < ActiveRecord::Migration[7.2]
  def change
    change_table :personal_information_requests, bulk: true do |t|
      t.column :processed, :boolean, default: false, null: false
      t.column :log, :text
    end

    reversible do |dir|
      dir.up do
        PersonalInformationRequest.unscoped.update_all(processed: true)
      end
    end
  end
end
