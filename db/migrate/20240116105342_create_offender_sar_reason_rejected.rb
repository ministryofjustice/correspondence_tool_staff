class CreateOffenderSarReasonRejected < ActiveRecord::Migration[6.1]
  def up
    create_table :reason_rejected do |t|
      t.column :reasons, :string
      t.timestamps
    end
  end
end
