class DeduplicateAndIndexCasesUsersTransitionsTrackers < ActiveRecord::Migration[8.1]
  def up
    # Remove duplicate rows created by the race condition in sync_for_case_and_user,
    # keeping the most recently updated record per case/user pair.
    execute <<~SQL
      DELETE FROM cases_users_transitions_trackers
      WHERE id NOT IN (
        SELECT DISTINCT ON (case_id, user_id) id
        FROM cases_users_transitions_trackers
        ORDER BY case_id, user_id, updated_at DESC NULLS LAST, id DESC
      )
    SQL

    add_index :cases_users_transitions_trackers,
              %i[case_id user_id],
              unique: true,
              name: "index_cutt_on_case_id_and_user_id"
  end

  def down
    remove_index :cases_users_transitions_trackers,
                 name: "index_cutt_on_case_id_and_user_id"
  end
end
