class AddReceivedDateToCorrespondence < ActiveRecord::Migration[5.0]
  def change
    add_column :correspondence, :received_date, :date
  end
end
