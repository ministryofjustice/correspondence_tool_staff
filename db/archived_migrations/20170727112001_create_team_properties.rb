class CreateTeamProperties < ActiveRecord::Migration[5.0]
  def change
    create_table :team_properties do |t|
      t.integer :team_id
      t.string :key
      t.text :value
      t.timestamps
    end

    add_index :team_properties, :team_id
    add_index :team_properties, [:team_id, :key, :value], unique: true
  end
end