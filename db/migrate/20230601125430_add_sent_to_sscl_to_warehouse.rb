class AddSentToSsclToWarehouse < ActiveRecord::Migration[6.1]
  def change
    add_column :warehouse_case_reports, :sent_to_sscl, :date
  end
end
