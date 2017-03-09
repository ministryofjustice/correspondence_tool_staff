class ChangeExemptionsToHabtm < ActiveRecord::Migration[5.0]
  def change
    remove_column :cases, :exemption_id, :integer
    create_table :cases_exemptions do |t|
      t.belongs_to :case, index: true
      t.belongs_to :exemption, index: true
      t.timestamps
    end
  end
end
