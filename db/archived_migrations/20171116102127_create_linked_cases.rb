class CreateLinkedCases < ActiveRecord::Migration[5.0]
  def change
    create_table :linked_cases do |t|
      t.integer :case_id, null: false
      t.integer :linked_case_id, null: false
    end
    add_index :linked_cases, :case_id
    add_index :linked_cases, %i[case_id linked_case_id], unique: true
  end
end
