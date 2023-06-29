class AddFullNameToUsers < ActiveRecord::Migration[5.0]
  class User < ApplicationRecord
  end

  def up
    add_column :users, :full_name, :string
    User.all.each do |user|
      user.update(
        full_name: user.email[/[^@]+/],
      )
    end
    change_column :users, :full_name, :string, null: false
  end

  def down
    remove_column :users, :full_name
  end
end
