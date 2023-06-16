class AddUniqueIndexToUserCaseTransitionTracker < ActiveRecord::Migration[5.0]
  def change
    # Add a unique index so that violations only crash the app once
    # rather than repeatedly CT-2151
    change_table :cases_users_transitions_trackers do |t|
      # add timestamps late to the party - so they have to be nullable
      t.timestamps null: true
      t.index %i[case_id user_id], unique: true
    end
  end
end
