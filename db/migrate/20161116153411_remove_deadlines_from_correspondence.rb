class RemoveDeadlinesFromCorrespondence < ActiveRecord::Migration[5.0]
  def change
    remove_column :correspondence, :internal_deadline, :date
    remove_column :correspondence, :external_deadline, :date
  end
end
