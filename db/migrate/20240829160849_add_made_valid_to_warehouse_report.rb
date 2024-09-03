class AddMadeValidToWarehouseReport < ActiveRecord::Migration[7.1]
  def change
    add_column :warehouse_case_reports, :user_made_valid, :string

    Case::Base.offender_sar.where("properties ->> 'case_originally_rejected' = 'true' AND LEFT(number,1) <> 'R'").find_each do |k|
      k.touch unless k.readonly?
    end
  end
end
