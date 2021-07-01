class UpdateBranstonUsers < ActiveRecord::DataMigration
  def up
    branston_team = BusinessUnit.dacu_branston
    branston_team.update_attribute(:role, "responder")
    branston_team.user_roles.map {|role| role.update_attribute(:role, "responder") }
  end

  def down
    branston_team = BusinessUnit.dacu_branston
    branston_team.update_attribute(:role, "manager")
    branston_team.user_roles.map {|role| role.update_attribute(:role, "manager") }
  end
end
