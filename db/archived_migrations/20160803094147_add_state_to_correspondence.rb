class AddStateToCorrespondence < ActiveRecord::Migration[5.0]
  def up
    add_column :correspondence, :state, :string, default: 'submitted'
  end

  def down
    remove_column :correspondence, :state, :string
  end
end
