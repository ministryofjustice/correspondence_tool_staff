class FixReasonForDeletion < ActiveRecord::Migration[5.0]
  def change
    change_column_null(:cases, :reason_for_deletion, true)
    change_column_default(:cases, :reason_for_deletion, to: nil, from: 'Unspecified')
  end
end
