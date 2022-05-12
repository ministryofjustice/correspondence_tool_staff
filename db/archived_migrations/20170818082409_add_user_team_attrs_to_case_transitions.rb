class AddUserTeamAttrsToCaseTransitions < ActiveRecord::Migration[5.0]
  def change
    add_column :case_transitions, :acting_user_id, :integer
    add_column :case_transitions, :acting_team_id, :integer
    add_column :case_transitions, :target_user_id, :integer
    add_column :case_transitions, :target_team_id, :integer
    remove_column :case_transitions, :user_id
  end
end
