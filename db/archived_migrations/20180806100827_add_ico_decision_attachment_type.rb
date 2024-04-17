class AddICODecisionAttachmentType < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    alter_enum :attachment_type, "ico_decision"
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          "reversing would require removing ico_decision case assignments"
  end
end
