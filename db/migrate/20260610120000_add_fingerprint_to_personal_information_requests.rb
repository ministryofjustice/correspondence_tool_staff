class AddFingerprintToPersonalInformationRequests < ActiveRecord::Migration[7.2]
  def change
    add_column :personal_information_requests, :fingerprint, :jsonb
  end
end
