class AddUserIdColumnToCaseTransitions < ActiveRecord::Migration[5.0]
  def up
    add_column :case_transitions, :user_id, :integer
    CaseTransition.connection.execute <<~EOSQL
      UPDATE case_transitions
             SET user_id = (metadata ->> 'user_id')::integer;
    EOSQL
  end

  def down
    CaseTransition.connection.execute <<~EOSQL
      UPDATE case_transitions
             SET metadata = jsonb_set(metadata, '{user_id}', user_id::text::jsonb);
    EOSQL
    remove_column :case_transitions, :user_id
  end
end
