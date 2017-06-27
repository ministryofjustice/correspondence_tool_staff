class AddReceivedByToCase < ActiveRecord::Migration[5.0]
  def up
    create_enum :received_by,
                'email',
                'post'

    add_column :cases, :received_by, :received_by
    add_index :cases, :received_by
  end

  def down
    remove_column :cases, :received_by

    drop_enum :received_by
  end
end
