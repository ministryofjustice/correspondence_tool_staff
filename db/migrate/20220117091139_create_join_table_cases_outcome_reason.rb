class CreateJoinTableCasesOutcomeReason < ActiveRecord::Migration[5.2]
  def change
    create_table :cases_outcome_reasons do |t|
      t.belongs_to :case, index: true
      t.belongs_to :outcome_reason, index: true
      t.timestamps
    end
  end
end
