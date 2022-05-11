class AddCaseClosureDetailsToCase < ActiveRecord::Migration[5.0]
  def change
    add_column :cases, :date_responded, :date
    add_column :cases, :outcome_id, :integer
    add_column :cases, :refusal_reason_id, :integer
    add_column :cases, :exemption_id, :integer
  end
end
