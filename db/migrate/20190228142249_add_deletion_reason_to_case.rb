class AddDeletionReasonToCase < ActiveRecord::Migration[5.0]
  def  change
    change_table :cases do |t|
      t.string :reason_for_deletion, null: true
    end
    Case::Base.find_each do |kase|
      kase.update!(reason_for_deletion: 'Unspecified')
    end
    change_column_null(:cases, :reason_for_deletion, false)
  end
end
