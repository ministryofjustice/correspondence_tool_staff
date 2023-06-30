class AddTeamRolesApproving < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    alter_enum :team_roles, "approving"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "reversing would require removing all approvers from teams"
  end
end
