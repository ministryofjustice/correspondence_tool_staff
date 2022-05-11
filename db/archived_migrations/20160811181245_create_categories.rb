class CreateCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :abbreviation
      t.integer :internal_time_limit
      t.integer :external_time_limit

      t.timestamps
    end
  end
end
