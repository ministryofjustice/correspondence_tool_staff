class CreatePersonalInformationRequest < ActiveRecord::Migration[6.1]
  def change
    create_table(:personal_information_requests) do |t|
      t.string :submission_id
      t.integer :last_accessed_by
      t.datetime :last_accessed_at
      t.boolean :deleted, default: false
      t.timestamps
    end
  end
end
