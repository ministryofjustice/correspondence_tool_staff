class AddUserToCase < ActiveRecord::Migration[5.0]
  # Allow Case reports to save which user created the case.
  # For existing cases, a 'Default User' is assigned.
  # The user creation is done here rather than data_migrations to ensure
  # the 'Default User' exists before the column is created.
  #
  # A 'DefaultUser' class to represent retrospective case creators
  # was determined to be unnecessary at this juncture.

  DEFAULT_USER_ID = -100

  def up
    User.new(
      id: DEFAULT_USER_ID,
      email: Settings.default_user_email, # ideally dud emails
      full_name: "",
      password: SecureRandom.base64(20),
      deleted_at: Date.today, # to prevent login attempts
    )
    .save!(validate: false)

    add_reference :cases, :user, foreign_key: true, null: false, default: DEFAULT_USER_ID
  end

  def down
    remove_reference :cases, :user
    User.delete(DEFAULT_USER_ID)
  end
end
