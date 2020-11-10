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
  enum role: {
         manager: 'manager',
         responder: 'responder',
         approver: 'approver',
         admin: 'admin',
       }

  belongs_to :user
  belongs_to :team, foreign_key: :team_id, class_name: 'Team'
  scope :manager_roles,   -> { where(role: :manager)  }
  scope :responder_roles, -> { where(role: :responder) }
  scope :approver_roles,  -> { where(role: :approver) }
  scope :active_approver_roles,  -> { where(role: :approver).joins(:team).where("teams": {deleted_at: nil}) }
end
