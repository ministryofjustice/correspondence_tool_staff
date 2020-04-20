class ChangeDateOfBirthNew < ActiveRecord::Migration[5.0]
  def self.up
    rename_column :cases, :date_of_birth_new, :date_of_birth
  end

  def self.down
    rename_column :cases, :date_of_birth, :date_of_birth_new
  end
end
