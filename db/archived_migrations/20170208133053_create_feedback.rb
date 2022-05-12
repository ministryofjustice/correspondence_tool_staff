class CreateFeedback < ActiveRecord::Migration[5.0]
  def change
    create_table :feedback do |t|
      t.jsonb :content

      t.timestamps
    end
  end
end
