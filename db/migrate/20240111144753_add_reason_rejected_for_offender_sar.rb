class AddReasonRejectedForOffenderSar < ActiveRecord::Migration[6.1]
  def change
    add_column :cases, :reason_rejected, :string
  end
end
