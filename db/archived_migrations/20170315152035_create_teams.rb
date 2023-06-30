class CreateTeams < ActiveRecord::Migration[5.0]
  def up
    enable_extension :citext
    create_table :teams do |t|
      t.string :name, null: false, index: true
      t.citext :email, null: false, index: true
      t.timestamps
    end

    create_enum :user_role, "creator", "manager", "responder"
    create_table :teams_users_roles do |t|
      t.belongs_to :team, index: true
      t.belongs_to :user, index: true
      t.column :role, :user_role, null: false
    end
    add_index :teams_users_roles,
              %i[team_id role user_id],
              unique: true,
              name: "index_team_table_team_id_role_user_id"
  end

  def down
    remove_index :teams_users_roles, %i[team_id role user_id]
    drop_table :teams_users_roles
    drop_enum :role
    drop_table :teams
    disable_extension :citext
  end
end
