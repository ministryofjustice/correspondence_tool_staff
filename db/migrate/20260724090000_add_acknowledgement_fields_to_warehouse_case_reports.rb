class AddAcknowledgementFieldsToWarehouseCaseReports < ActiveRecord::Migration[8.1]
  def change
    change_table :warehouse_case_reports, bulk: true do |t|
      t.date :acknowledgement_deadline
      t.date :acknowledgement_sent_at
    end
  end
end
