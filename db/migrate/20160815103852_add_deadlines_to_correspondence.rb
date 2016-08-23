class AddDeadlinesToCorrespondence < ActiveRecord::Migration[5.0]
  def up
    add_column :correspondence, :internal_deadline, :date
    add_column :correspondence, :external_deadline, :date
  end

  def down
    remove_column :correspondence, :internal_deadline, :date
    remove_column :correspondence, :external_deadline, :date
  end
end
