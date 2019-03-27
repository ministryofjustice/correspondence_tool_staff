class AddDeletionReasonToCase < ActiveRecord::Migration[5.0]
  def  change
    # This migration is broken - see following one (fix_reason_for_deletion) for fix
    change_table :cases do |t|
      t.string :reason_for_deletion, null: true, default: 'Unspecified'
    end
  end
end
