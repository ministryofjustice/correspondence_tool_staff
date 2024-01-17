class CreateOffenderSarReasonRejected < ActiveRecord::Migration[6.1]
  def change
    create_table :offender_sar_reason_rejecteds do |t|
      t.column :reason_rejected, :string, index: true
      t.timestamps
    end
  end
end
