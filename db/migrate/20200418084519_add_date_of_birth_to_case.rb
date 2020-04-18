class AddDateOfBirthToCase < ActiveRecord::Migration[5.0]
  def change
    add_column :cases, :date_of_birth_new, :date, null: true
  end
end
