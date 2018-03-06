class BusinessUnit < Team

  # usage:
  #   set_correspondence_type_roles(category_abbreviation: 'SAR', roles: %w{ edit manage view respond })
  # #
  def set_category_roles(category_abbreviation:, roles:)
    cat = CorrespondenceType.find_by_abbreviation!(category_abbreviation.upcase)
    tcr = TeamCorrespondenceTypeRole.find_by(team_id: id, correspondence_type_id: cat.id)
    if tcr.nil?
      category_roles << TeamCorrespondenceTypeRole.new_for(team: self, correspondence_type: cat, roles: roles)
    else
      tcr.update_roles(roles)
    end
  end

end



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
