class AddTypeColumnToLinkedCases < ActiveRecord::Migration[5.0]
  def change
    add_column :linked_cases, :type, :string, default: "related"
    remove_index :linked_cases, column: %i[case_id linked_case_id], unique: true
    add_index :linked_cases, %i[case_id linked_case_id type], unique: true
  end
end
