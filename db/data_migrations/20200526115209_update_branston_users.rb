class UpdateBranstonUsers < ActiveRecord::DataMigration
  # rubocop:disable Rails/SkipsModelValidations
  def up
    if BusinessUnit.find_by(code: Settings.offender_sar_cases.default_managing_team)
      branston_team = BusinessUnit.dacu_branston
      branston_team.update_attribute(:role, "responder")
      branston_team.user_roles.map { |role| role.update_attribute(:role, "responder") }
    end
  end

  def down
    if BusinessUnit.find_by(code: Settings.offender_sar_cases.default_managing_team)
      branston_team = BusinessUnit.dacu_branston
      branston_team.update_attribute(:role, "manager")
      branston_team.user_roles.map { |role| role.update_attribute(:role, "manager") }
    end
  end
  # rubocop:enable Rails/SkipsModelValidations
end
