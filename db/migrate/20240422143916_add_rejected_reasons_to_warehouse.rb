class AddRejectedReasonsToWarehouse < ActiveRecord::Migration[7.1]
  def change
    change_table :warehouse_case_reports, bulk: true do |t|
      t.string :rejected_reasons
      t.string :other_rejected_reason
    end
  end
end
