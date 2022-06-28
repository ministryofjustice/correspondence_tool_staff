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
         team_admin: 'team_admin',
       }

  belongs_to :user
  belongs_to :team, class_name: 'Team'
  scope :manager_roles,   -> { where(role: :manager) }
  scope :responder_roles, -> { where(role: :responder) }
  scope :approver_roles,  -> { where(role: :approver) }
  scope :team_admin_roles, -> { where(role: :team_admin) }
  scope :active_approver_roles, -> { where(role: :approver).joins(:team).where("teams": {deleted_at: nil}) }
  scope :active_manager_roles, -> { where(role: :manager).joins(:team).where("teams": {deleted_at: nil}) }
end
