class PopulateTeamCategoryRoles < ActiveRecord::Migration[5.0]
  def up
    BusinessUnit.where(role: 'manager').each do |bu|
      bu.set_category_roles(category_abbreviation: 'foi', roles: %w{ view edit manage })
    end

    BusinessUnit.where(role: 'approver').each do |bu|
      bu.set_category_roles(category_abbreviation: 'foi', roles: %w{ view approve })
    end

    BusinessUnit.where(role: 'responder').each do |bu|
      bu.set_category_roles(category_abbreviation: 'foi', roles: %w{ view respond })
    end
  end

  def down
    TeamCategoryRole.destroy_all
  end
end
