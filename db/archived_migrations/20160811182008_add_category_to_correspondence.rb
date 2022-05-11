class AddCategoryToCorrespondence < ActiveRecord::Migration[5.0]
  def up
    add_reference :correspondence, :category, foreign_key: true, null: true
  end

  def down
    remove_reference :correspondence, :category
  end
end
