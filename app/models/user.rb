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
  include Warehousable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable and :omniauthable

  devise :database_authenticatable, :timeoutable,
    :trackable, :validatable, :recoverable, :lockable

  has_paper_trail only: [:email, :encrypted_password, :full_name, :deleted_at]

  # Most uses of User are in authentication - so preload team_roles and teams
  # so that we don't issue lots of DB queries when constantly asking what a user can do.
  #
  # Needing teams in this list (along with managing_teams, approving_team and responding_teams)
  # implies that we could have better implementations of the above based on the 'teams' collection
  default_scope do
    includes(:team_roles,
             :teams,
             :responding_team_roles,
             :responding_teams,
             :approving_team_roles,
             :approving_team,
             :managing_team_roles,
             :managing_teams)
  end

  has_many :assignments
  has_many :cases, through: :assignments
  has_many :team_roles, class_name: 'TeamsUsersRole'
  has_many :teams, through: :team_roles
  has_many :managing_team_roles,
           -> { active_manager_roles },
           class_name: 'TeamsUsersRole'
  has_many :responding_team_roles,
           -> { responder_roles  },
           class_name: 'TeamsUsersRole'
  has_one :approving_team_roles,
           -> { active_approver_roles  },
           class_name: 'TeamsUsersRole'
  has_one :team_admin_team_roles,
           -> { team_admin_roles  },
           class_name: 'TeamsUsersRole'
  has_many :team_admin_teams, through: :team_admin_team_roles, source: :team
  has_many :managing_teams, through: :managing_team_roles, source: :team
  has_many :responding_teams, through: :responding_team_roles, source: :team
  has_many :data_requests
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

  ROLE_WEIGHTINGS = {
    'manager'   => 100,
    'approver'  => 200,
    'responder' => 300
  }.freeze

  def admin?
    team_roles.admin.any?
  end

  def manager?
    managing_teams.any?
  end

  def team_admin?
    team_admin_teams.any?
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

  def case_team(kase)
    # need to sort with manager first so that if we are both manager and something else, we don't
    # try to execute the action with our lower authority (which might fail)
    # When designing the state flow,  the permission for each state and actions should follow the 
    # hierarchy of roles which is manager - approver - responder
    if teams_for_case(kase).any?
      case_teams = teams_for_case(kase)
    else
      case_teams = teams
    end
    self.class.sort_teams_by_roles(case_teams).first
  end

  def case_team_for_event(kase, event)
    # Return the team which have the permission for performing the event for 
    # a particular kase under current state. If multiple teams are found 
    # the team with highest authority will be returned
    available_teams = kase.state_machine.teams_that_can_trigger_event_on_case(
      event_name: event, 
      user: self)
    self.class.sort_teams_by_roles(available_teams).first
  end

  # Note: Role Weightings can be very different depending on the event
  def self.sort_teams_by_roles(teams, role_weightings = ROLE_WEIGHTINGS)
    teams.sort do |a, b|
      role_weightings[a.role] <=> role_weightings[b.role]
    end
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
    teams.active.size > 1
  end

  def password_blacklist
    if password.present? and password.in?(bad_passwords)
      errors.add :password, "too easily guessable. Please use another password at least 10 characters long."
    end
  end

  def deactivated?
    !active_for_authentication?
  end

  def permitted_correspondence_types
    types = all_possible_user_correspondence_types
    
    add_sar_ir_to_permitted_types_if_sars_allowed(types)
    
    types.delete(CorrespondenceType.sar) unless FeatureSet.sars.enabled?
    types.delete(CorrespondenceType.ico) unless FeatureSet.ico.enabled?
    types.delete(CorrespondenceType.offender_sar) unless FeatureSet.offender_sars.enabled?
    types.delete(CorrespondenceType.sar_internal_review) unless FeatureSet.sar_internal_review.enabled?
    types << CorrespondenceType.overturned_foi if types.include?(CorrespondenceType.foi)
    types << CorrespondenceType.overturned_sar if types.include?(CorrespondenceType.sar)
    types
  end

  def add_sar_ir_to_permitted_types_if_sars_allowed(types)
    does_not_have_sar_ir = types.exclude?(CorrespondenceType.sar_internal_review)
    has_sar = types.include?(CorrespondenceType.sar)
    if has_sar && does_not_have_sar_ir 
      types << CorrespondenceType.sar_internal_review
    end
  end

  def other_teams_names(current_team)
    self.teams.delete(current_team)
    self.teams.map(&:name).to_sentence
  end

  private

  def all_possible_user_correspondence_types
    self.teams.collect(&:correspondence_types).flatten.uniq
  end

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
