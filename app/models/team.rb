# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Team < ApplicationRecord
  has_many :user_roles, class_name: 'TeamsUsersRole'
  has_many :users, through: :user_roles
  has_many :responder_user_roles,
           -> { responder_roles  },
           class_name: 'TeamsUsersRole'
  has_many :manager_user_roles,
           -> { manager_roles },
           class_name: 'TeamsUsersRole'

  has_many :managers, through: :manager_user_roles, source: :user
  has_many :responders, through: :responder_user_roles, source: :user

  scope :responding, -> {
    joins(:user_roles).where(teams_users_roles: { role: 'responder' }).distinct
  }
  scope :managing, -> {
    joins(:user_roles).where(teams_users_roles: { role: 'manager' }).distinct
  }
end
