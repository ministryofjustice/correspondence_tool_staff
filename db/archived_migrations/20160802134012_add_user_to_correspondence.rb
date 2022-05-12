class AddUserToCorrespondence < ActiveRecord::Migration[5.0]
  def up
    add_reference :correspondence, :user, foreign_key: true, null: true
  end

  def down
    remove_reference :correspondence, :user
  end
end
