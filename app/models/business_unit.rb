# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#  parent_id  :integer
#  role       :string
#  code       :string
#

class BusinessUnit < Team

  VALID_ROLES = %w{ responder approver manager }.freeze
  validates :parent_id, presence: true

  belongs_to :directorate, foreign_key: 'parent_id'

  has_one :business_group, through: :directorate

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

  scope :managing, -> { where(role: 'manager') }
  scope :approving, -> { where(role: 'approver') }
  scope :responding, -> { where(role: 'responder') }

  def valid_role
    unless role.in?(VALID_ROLES)
      errors.add(:role, :invalid)
    end
  end

  def self.dacu_disclosure
    find_by!(code: Settings.foi_cases.default_clearance_team)
  end

  def dacu_disclosure?
    code == Settings.foi_cases.default_clearance_team
  end

  def self.dacu_bmt
     find_by!(code:Settings.foi_cases.default_managing_team)
  end

  def dacu_bmt?
    code == Settings.foi_cases.default_managing_team
  end

  def self.press_office
    find_by!(code: Settings.press_office_team_code)
  end

  def press_office?
    code == Settings.press_office_team_code
  end

  def self.private_office
    find_by!(code: Settings.private_office_team_code)
  end

  def private_office?
    code == Settings.private_office_team_code
  end

end
