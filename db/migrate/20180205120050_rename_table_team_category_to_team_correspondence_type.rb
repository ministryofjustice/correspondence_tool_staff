class RenameTableTeamCategoryToTeamCorrespondenceType < ActiveRecord::Migration[5.0]
  def up
    rename_index :team_category_roles,
                 :index_team_category_roles_on_category_id_and_team_id,
                 :index_team_correspondence_type_roles_on_type_id_and_team_id
    rename_table :team_category_roles,
                 :team_correspondence_type_roles
    rename_column :team_correspondence_type_roles,
                  :category_id,
                  :correspondence_type_id
  end

  def down
    rename_column :team_correspondence_type_roles,
                  :correspondence_type_id,
                  :category_id
    rename_table :team_correspondence_type_roles,
                 :team_category_roles
    rename_index :team_category_roles,
                 :index_team_correspondence_type_roles_on_type_id_and_team_id,
                 :index_team_category_roles_on_category_id_and_team_id
  end
end
