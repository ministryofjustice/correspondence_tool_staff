class CreateCasesUsersTransitionsTrackers < ActiveRecord::Migration[5.0]
  def change
    create_table :cases_users_transitions_trackers do |t|
      t.integer :case_id
      t.integer :user_id
      t.integer :case_transition_id

      t.index :case_id
      t.index :user_id
    end
  end
end
