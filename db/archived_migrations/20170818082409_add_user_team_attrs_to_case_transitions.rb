class AddUserTeamAttrsToCaseTransitions < ActiveRecord::Migration[5.0]
  # rubocop:disable Rails/ReversibleMigration
  def change
    add_column :case_transitions, :acting_user_id, :integer
    add_column :case_transitions, :acting_team_id, :integer
    add_column :case_transitions, :target_user_id, :integer
    add_column :case_transitions, :target_team_id, :integer
    remove_column :case_transitions, :user_id
  end
  # rubocop:enable Rails/ReversibleMigration
end
