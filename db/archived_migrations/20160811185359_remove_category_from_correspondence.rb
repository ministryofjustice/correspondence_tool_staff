class RemoveCategoryFromCorrespondence < ActiveRecord::Migration[5.0]
  def up
    remove_column :correspondence, :category
  end

  def down
    add_column :correspondence, :category, :string
  end
end
