# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  full_name              :string           not null
#

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable and :omniauthable

  devise :database_authenticatable, :timeoutable,
    :trackable, :validatable, :recoverable

  has_many :cases, through: :assignments
  has_many :assignments
  has_many :team_roles, class_name: 'TeamsUsersRole'
  has_many :teams, through: :team_roles
  has_many :managing_team_roles,
           -> { manager_roles },
           class_name: 'TeamsUsersRole'
  has_many :responding_team_roles,
           -> { responder_roles  },
           class_name: 'TeamsUsersRole'
  has_one :approving_team_roles,
           -> { approver_roles  },
           class_name: 'TeamsUsersRole'
  has_many :managing_teams, through: :managing_team_roles, source: :team
  has_many :responding_teams, through: :responding_team_roles, source: :team
  has_one  :approving_team, through: :approving_team_roles, source: :team

  validates :full_name, presence: true

  scope :managers, -> {
    joins(:team_roles).where(teams_users_roles: { role: 'manager' })
  }
  scope :responders, -> {
    joins(:team_roles).where(teams_users_roles: { role: 'responder' })
  }
  scope :approvers, -> {
    joins(:team_roles).where(teams_users_roles: { role: 'approver' })
  }

  def manager?
    managing_teams.any?
  end

  def responder?
    responding_teams.any?
  end

  def approver?
    approving_team.present?
  end

  def press_officer?
    approving_team == BusinessUnit.press_office
  end

  def private_officer?
    approving_team == BusinessUnit.private_office
  end

  def roles
    team_roles.pluck(:role).uniq
  end

  def teams_for_case(kase)
    kase.teams & teams
  end

  def roles_for_team(team)
    team_roles.where(team_id: team.id)
  end

  def decorated_roles_for_team(team)
    team_roles.where(team_id: team.id).map(&:role).uniq.join(', ')
  end
end
