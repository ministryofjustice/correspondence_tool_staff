class CreateAssignments < ActiveRecord::Migration[5.0]
  def up
    create_enum :state, 'pending', 'rejected', 'accepted'
    create_enum :assignment_type, 'caseworker', 'drafter'

    create_table :assignments do |t|
      t.column :assignment_type, :assignment_type, index: true
      t.column :state, :state, default: 'pending', index: true
      t.references :correspondence
      t.references :assignee
      t.references :assigner

      t.timestamps
    end
  end

  def down
    drop_table :assignments

    drop_enum :state
    drop_enum :assignment_type
  end

end
