class AddDeletionReasonToCase < ActiveRecord::Migration[5.0]
  def change
    change_table :cases do |t|
      # No default - otherwise non-deleted cases get a reason for deletion
      # also can't backfill cases as some old deleted cases don't meet the current validations
      t.string :reason_for_deletion
    end
  end
end
