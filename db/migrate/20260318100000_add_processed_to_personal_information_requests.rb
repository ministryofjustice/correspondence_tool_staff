class AddProcessedToPersonalInformationRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :personal_information_requests, :processed, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        PersonalInformationRequest.unscoped.update_all(processed: true)
      end
    end
  end
end
