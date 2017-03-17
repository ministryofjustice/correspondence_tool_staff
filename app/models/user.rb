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
  has_many :managing_teams, through: :managing_team_roles, source: :team
  has_many :responding_teams, through: :responding_team_roles, source: :team

  validates :full_name, presence: true

  scope :responders, -> {
    joins(:team_roles).where(teams_users_roles: { role: 'responder' })
  }
  scope :managers, -> {
    joins(:team_roles).where(teams_users_roles: { role: 'manager' })
  }

  # def manager?
  #   team_roles.managing_teams.include? self
  # end

  def manager?
    not managing_teams.empty?
  end

  def responder?
    not responding_teams.empty?
  end
end
