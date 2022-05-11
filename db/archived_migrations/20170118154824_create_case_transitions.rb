class CreateCaseTransitions < ActiveRecord::Migration[5.1]
  def change
    create_table :case_transitions do |t|
      t.string :event
      t.string :to_state, null: false
      t.jsonb :metadata, default: {}
      t.integer :sort_key, null: false
      t.integer :case_id, null: false
      t.boolean :most_recent, null: false
      t.timestamps null: false
    end

    add_index(:case_transitions,
              [:case_id, :sort_key],
              unique: true,
              name: "index_case_transitions_parent_sort")
    add_index(:case_transitions,
              [:case_id, :most_recent],
              unique: true,
              where: 'most_recent',
              name: "index_case_transitions_parent_most_recent")
  end
end
