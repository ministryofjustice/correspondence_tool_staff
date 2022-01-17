class AddTableForAnonymizer < ActiveRecord::Migration[5.2]
  def change
    create_table :users_settings_for_anonymizer do |t|
      t.integer :user_id
      t.string :full_name
      t.string :email
      t.string :encrypted_password
      t.string :team_id
      t.string :role
    end
  end
end
