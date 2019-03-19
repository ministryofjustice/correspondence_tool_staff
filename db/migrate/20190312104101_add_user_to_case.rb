class AddUserToCase < ActiveRecord::Migration[5.0]
  # To allow Case reports to show which user created the case.
  # For existing cases, a 'dummy' user must be created with a fixed ID.
  # The user creation is done here rather than data_migrations to ensure
  # the DefaultUser exists before the column is created.
  def up
    DefaultUser.build!
    add_reference :cases, :user, foreign_key: true, null:false, default: -100
  end

  def down
    remove_reference :cases, :user
    User.delete(DefaultUser::ID)
  end
end
