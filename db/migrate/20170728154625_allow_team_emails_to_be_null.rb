class AllowTeamEmailsToBeNull < ActiveRecord::Migration[5.0]
  def up
    enable_extension :citext
    change_column_null :teams, :email, :citext, false
  end
  def down
    enable_extension :citext
    change_column_null :teams, :email, :citext, true
  end
end
