class AddAdminTeamUserRole < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    alter_enum :user_role, "admin"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "reversing would require removing user_role enum"
  end
end
