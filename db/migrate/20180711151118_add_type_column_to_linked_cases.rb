class AddTypeColumnToLinkedCases < ActiveRecord::Migration[5.0]
  def change
    add_column :linked_cases, :type, :string, default: 'related'
  end
end
