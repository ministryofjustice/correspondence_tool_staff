class AddRequestToCaseAttachmentType < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    alter_enum :attachment_type, 'request'
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          'reversing would require removing request case assignments'
  end
end
