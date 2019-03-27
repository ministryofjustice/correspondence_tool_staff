class FixReasonForDeletion < ActiveRecord::Migration[5.0]
  def change
    change_column_null(:cases, :reason_for_deletion, true)
    change_column_default(:cases, :reason_for_deletion, to: nil, from: 'Unspecified')

    Case::Base.unscoped.soft_deleted.each { |kase| kase.update!(reason_for_deletion: 'Unspecified') }
  end
end
