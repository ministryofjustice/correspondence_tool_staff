class AddUniqueIndexToUserCaseTransitionTracker < ActiveRecord::Migration[5.0]
  def change
    # Add a unique index so that violations only crash the app once
    # rather than repeatedly CT-2151
    change_table :cases_users_transitions_trackers do |t|
      t.index [:case_id, :user_id], unique: true
    end
  end
end
