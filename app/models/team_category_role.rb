# == Schema Information
#
# Table name: team_category_roles
#
#  id          :integer          not null, primary key
#  category_id :integer
#  team_id     :integer
#  view        :boolean          default(FALSE)
#  edit        :boolean          default(FALSE)
#  manage      :boolean          default(FALSE)
#  respond     :boolean          default(FALSE)
#  approve     :boolean          default(FALSE)
#

class TeamCategoryRole < ActiveRecord::Base

  belongs_to :category

  def self.new_for(team:, category:, roles:)
    params = params_from_roles(roles).merge(team_id: team.id, category_id: category.id)
    self.new(params)
  end

  def update_roles(roles)
    params = TeamCategoryRole.params_from_roles(roles)
    update!(params)
  end

  def self.params_from_roles(roles)
    params = {
        view: false,
        edit: false,
        manage: false,
        respond: false,
        approve: false
    }
    roles.each { |role| params[role.to_sym] = true }
    params
  end




end
