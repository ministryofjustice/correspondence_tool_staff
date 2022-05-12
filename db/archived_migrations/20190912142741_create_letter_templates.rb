class CreateLetterTemplates < ActiveRecord::Migration[5.0]
  def change
    create_table :letter_templates do |t|
      t.string :name
      t.string :abbreviation
      t.string :body
      t.string :template_type

      t.timestamps
    end

    add_index :letter_templates, :abbreviation, unique: true
  end
end
