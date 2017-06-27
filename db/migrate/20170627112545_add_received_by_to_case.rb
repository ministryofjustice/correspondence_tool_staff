class AddReceivedByToCase < ActiveRecord::Migration[5.0]
  def up
    create_enum :cases_received_by,
                'email',
                'post'

    add_column :cases, :received_by, :cases_received_by
  end

  def down
    remove_column :cases, :received_by

    drop_enum :cases_received_by
  end
end
