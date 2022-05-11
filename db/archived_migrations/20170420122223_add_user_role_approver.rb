class AddUserRoleApprover < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    alter_enum :user_role, 'approver'
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          'reversing would require removing approver case assignments, etc'
  end
end
