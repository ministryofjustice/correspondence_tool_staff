class CreateLetterTemplates < ActiveRecord::Migration[5.0]
  def change
    create_table :letter_templates do |t|
      t.string :name
      t.string :body
      t.string :template_type

      t.timestamps
    end
  end
end
