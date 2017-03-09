class CreateCaseClosureMetadata < ActiveRecord::Migration[5.0]
  def change
    create_table :case_closure_metadata do |t|
      t.string :type
      t.string :subtype
      t.string :name
      t.string :abbreviation
      t.integer :sequence_id

      t.timestamps
    end
  end
end
