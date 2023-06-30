class AddPermissionFlagToTeamCorrespondenceType < ActiveRecord::Migration[5.2]
  def change
    add_column :team_correspondence_type_roles, :administer_team, :boolean, default: false, null: false
    Case::Base.connection.execute <<~EOSQL
      ALTER TYPE user_role ADD VALUE 'team_admin';
    EOSQL
  end
end
