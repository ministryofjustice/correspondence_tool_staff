class ConvertTeamRolePropertyToAttribute < ActiveRecord::Migration[5.0]
  def up
    teams = BusinessUnit.all
    teams.each do |team|
      convert_role_to_attribute(team)
    end
  end

  def down
    teams = BusinessUnit.all
    teams.each do |team|
      convert_role_to_property(team)
    end
  end

  private
  def convert_role_to_attribute(team)
    property = team.properties.where(key: 'role').first
    role = property&.value || 'responder'
    team.role = role
    team.save!
    property.destroy
  end

  def convert_role_to_property(team)
    team.properties.where(key: 'role').map(&:destroy)
    team.properties << TeamProperty.new(key: 'role', value: team.role)
    team.save!
  end


end
