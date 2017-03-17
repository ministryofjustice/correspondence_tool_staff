# == Schema Information
#
# Table name: teams_users_roles
#
#  id      :integer          not null, primary key
#  team_id :integer
#  user_id :integer
#  role    :enum             not null
#

class TeamsUsersRole < ApplicationRecord
  enum role: { manager: 'manager', responder: 'responder' }

  belongs_to :user
  belongs_to :team
  scope :manager_roles,   -> { where(role: :manager)  }
  scope :responder_roles, -> { where(role: :responder) }
end
