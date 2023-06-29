class CreateTeamCategoryRolesTable < ActiveRecord::Migration[5.0]
  def change
    create_table :team_category_roles do |t|
      t.integer :category_id
      t.integer :team_id
      t.boolean :view, default: false
      t.boolean :edit, default: false
      t.boolean :manage, default: false
      t.boolean :respond, default: false
      t.boolean :approve, default: false

      t.timestamps
    end

    add_index :team_category_roles, %i[category_id team_id], unique: true
  end
end
