class CreateCategoryReferences < ActiveRecord::Migration[5.2]
  def change
    create_table :category_references do |t|
      t.string :code
      t.string :category
      t.string :value
      t.integer :display_order
      t.boolean :deactivated

      t.timestamps
    end
    add_index :category_references, :code, unique: true
  end
end
