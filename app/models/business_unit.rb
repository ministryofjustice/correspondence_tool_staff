# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#

class BusinessUnit < Team
  validates :parent_id, presence: true

  belongs_to :directorate, foreign_key: 'parent_id'

  has_many :manager_user_roles,
           -> { manager_roles },
           class_name: 'TeamsUsersRole',
           foreign_key: :team_id
  has_many :responder_user_roles,
           -> { responder_roles  },
           class_name: 'TeamsUsersRole',
           foreign_key: :team_id
  has_many :approver_user_roles,
           -> { approver_roles  },
           class_name: 'TeamsUsersRole',
           foreign_key: :team_id

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

  def self.dacu_disclosure
    find_by!(name: Settings.foi_cases.default_clearance_team)
  end

  def dacu_disclosure?
    name == Settings.foi_cases.default_clearance_team
  end

  def self.press_office
    find_by!(name: Settings.press_office_team_name)
  end

  def press_office?
    name == Settings.press_office_team_name
  end

  def self.private_office
    find_by!(name: Settings.private_office_team_name)
  end

  def private_office?
    name == Settings.private_office_team_name
  end
end
