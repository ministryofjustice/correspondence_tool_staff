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

  validates :name, uniqueness: true

  has_many :user_roles, class_name: 'TeamsUsersRole'
  has_many :users, through: :user_roles
  has_many :manager_user_roles,
           -> { manager_roles },
           class_name: 'TeamsUsersRole'
  has_many :responder_user_roles,
           -> { responder_roles  },
           class_name: 'TeamsUsersRole'
  has_many :approver_user_roles,
           -> { approver_roles  },
           class_name: 'TeamsUsersRole'

  has_many :managers, through: :manager_user_roles, source: :user
  has_many :responders, through: :responder_user_roles, source: :user
  has_many :approvers, through: :approver_user_roles, source: :user

  scope :managing, -> {
    joins(:user_roles).where(teams_users_roles: { role: 'manager' }).distinct
  }
  scope :responding, -> {
    joins(:user_roles).where(teams_users_roles: { role: 'responder' }).distinct
  }
  scope :approving, -> {
    joins(:user_roles).where(teams_users_roles: { role: 'approver' }).distinct
  }
  scope :with_user, ->(user) {
    includes(:user_roles)
      .where(teams_users_roles: { user_id: user.id })
  }

  def self.dacu_disclosure
    where(name: Settings.foi_cases.default_clearance_team).first
  end

  def dacu_disclosure?
    name == Settings.foi_cases.default_clearance_team
  end

  def self.press_office
    where(name: Settings.press_office_team_name).first
  end

  def press_office?
    name == Settings.press_office_team_name
  end

  def self.private_office
    where(name: Settings.private_office_team_name).first
  end

  def private_office?
    name == Settings.private_office_team_name
  end
end
