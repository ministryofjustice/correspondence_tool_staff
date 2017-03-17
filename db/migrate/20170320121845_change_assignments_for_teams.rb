class ChangeAssignmentsForTeams < ActiveRecord::Migration[5.0]
  def up
    create_enum :team_roles, 'managing', 'responding'

    change_table :assignments do |t|
      t.column :role, :team_roles
      t.rename :assignee_id, :team_id
      t.change :team_id, :integer, null: false
      t.change :case_id, :integer, null: false
      t.belongs_to :user
      t.remove :assignment_type
      t.remove_belongs_to :assigner
    end

    drop_enum :assignment_type
  end

  def down
    create_enum :assignment_type, 'caseworker', 'drafter'

    change_table :assignments do |t|
      t.remove :role
      t.rename :team_id, :assignee_id
      t.change :assignee_id, :integer, null: true
      t.change :case_id, :integer, null: true
      t.remove_belongs_to :user
      t.column :assignment_type, :assignment_type
      t.belongs_to :assigner
    end

    drop_enum :team_roles
  end
end
