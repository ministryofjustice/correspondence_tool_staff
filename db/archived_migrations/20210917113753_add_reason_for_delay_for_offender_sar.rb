class AddReasonForDelayForOffenderSar < ActiveRecord::Migration[5.2]
  def change
    add_column :cases, :reason_for_lateness_id, :bigint
    add_column :cases, :reason_for_lateness_note, :string
  end

  def down
    drop_column :cases, :reason_for_lateness_id
    drop_column :cases, :reason_for_lateness_note
  end
end
