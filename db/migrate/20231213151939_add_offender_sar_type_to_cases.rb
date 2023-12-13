class AddOffenderSarTypeToCases < ActiveRecord::Migration[6.1]
  def change
    add_column :cases, :offender_sar_type, :string
  end
end
