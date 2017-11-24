class AddAppealOutcomeIdToCase < ActiveRecord::Migration[5.0]
  def change
    add_column :cases, :appeal_outcome_id, :integer
  end
end
