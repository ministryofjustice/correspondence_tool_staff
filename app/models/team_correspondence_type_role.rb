# == Schema Information
#
# Table name: team_correspondence_type_roles
#
#  id                     :integer          not null, primary key
#  correspondence_type_id :integer
#  team_id                :integer
#  view                   :boolean          default(FALSE)
#  edit                   :boolean          default(FALSE)
#  manage                 :boolean          default(FALSE)
#  respond                :boolean          default(FALSE)
#  approve                :boolean          default(FALSE)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  administer_team        :boolean          default(FALSE), not null
#

class TeamCorrespondenceTypeRole < ApplicationRecord
  belongs_to :team
  belongs_to :correspondence_type

  validates :correspondence_type_id, presence: true

  before_create do
    roles_for_team(team).each do |role|
      self[role] = true
    end
  end

  def update_roles(roles)
    params = TeamCorrespondenceTypeRole.params_from_roles(roles)
    update!(params)
  end

  def self.params_from_roles(roles)
    params = {
      view: false,
      edit: false,
      manage: false,
      respond: false,
      approve: false,
      administer_team: false,
    }
    roles.each { |role| params[role.to_sym] = true }
    params
  end

private

  def roles_for_team(team)
    {
      manager: %i[view edit manage],
      responder: %i[view respond],
      approver: %i[view approve],
      team_admin: %i[view administer_team],
    }[team.role.to_sym] || []
  end
end
