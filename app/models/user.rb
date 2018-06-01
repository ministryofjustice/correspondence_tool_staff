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
#  deleted_at             :datetime
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable and :omniauthable

  devise :database_authenticatable, :timeoutable,
    :trackable, :validatable, :recoverable, :lockable

  has_paper_trail only: [:email, :encrypted_password, :full_name, :deleted_at]

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
  validate :password_blacklist

  scope :managers, -> {
    joins(:team_roles).where(teams_users_roles: { role: 'manager' })
  }
  scope :responders, -> {
    joins(:team_roles).where(teams_users_roles: { role: 'responder' })
  }
  scope :approvers, -> {
    joins(:team_roles).where(teams_users_roles: { role: 'approver' })
  }
  scope :active_users, -> { where(deleted_at: nil) }

  def admin?
    team_roles.admin.any?
  end

  def manager?
    managing_teams.any?
  end

  def responder?
    responding_teams.any?
  end

  def responder_only?
    managing_teams.none? && approving_team.blank?
  end

  def approver?
    approving_team.present?
  end

  def disclosure_specialist?
    approving_team == BusinessUnit.dacu_disclosure
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

  def roles_for_case(kase)
    user_assignments = kase.assignments.where(user_id: self.id).map{ |a| a.team.role }
    if self.teams.include?(kase.managing_team)
      user_assignments << 'manager'
    end
    user_assignments
  end

  def roles_for_team(team)
    team_roles.where(team_id: team.id)
  end

  def decorated_roles_for_team(team)
    team_roles.where(team_id: team.id).map(&:role).uniq.join(', ')
  end

  def soft_delete
   update_attribute(:deleted_at, Time.current)
  end

  def active_for_authentication?
    super && !deleted_at
  end

  def has_live_cases_for_team?(team)
    cases.with_teams(team).where.not(current_state: ['closed', 'responded']).any?
  end

  def multiple_team_member?
    team_roles.size > 1
  end

  def password_blacklist
    if password.present? and password.in?(bad_passwords)
      errors.add :password, "too easily guessable. Please use another password at least 10 characters long."
    end
  end

  def deactivated?
    !active_for_authentication?
  end

  private
  def bad_passwords
    %w{
        1234567890
        qwertyuiop
        1q2w3e4r5t
        q1w2e3r4t5
        password12
        password123
        aaaaaaaaaa
        zzzzzzzzzz
        1111111111
    }
  end

end
