class AddDeletionReasonToCase < ActiveRecord::Migration[5.0]
  def up
    change_table :cases do |t|
      t.string :reason_for_deletion, null: false, default: 'Unspecified'
    end
  end
end
