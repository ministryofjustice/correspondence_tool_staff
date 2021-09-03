class CreateCategoryReferences < ActiveRecord::Migration[5.2]
  def change
    create_table :category_references do |t|
      t.string :category
      t.string :code
      t.string :value
      t.integer :display_order
      t.boolean :deactivated, default: false

      t.timestamps
    end
    add_index :category_references, [:category, :code], unique: true
  end
end
