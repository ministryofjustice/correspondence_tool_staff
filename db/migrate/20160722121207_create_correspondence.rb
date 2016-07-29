class CreateCorrespondence < ActiveRecord::Migration[5.0]
  def change
    create_table :correspondence do |t|
      t.string :name
      t.string :email
      t.string :category
      t.string :topic
      t.text :message

      t.timestamps
    end
  end
end
