class AddMetadatumColumnsToWarehouseCaseReports < ActiveRecord::Migration[5.0]
  def change
    %w[
      info_held_status_id
      refusal_reason_id
      outcome_id
      appeal_outcome_id
    ].each do |field|
      add_column :warehouse_case_reports, field, :integer
    end
  end
end
