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
#  deleted_at :datetime
#

class BusinessUnit < Team

  VALID_ROLES = %w{ responder approver manager }.freeze
  validates :parent_id, presence: true
  validates_presence_of :correspondence_type_roles


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
  has_many :correspondence_type_roles,
           -> { distinct },
           foreign_key: :team_id,
           class_name: 'TeamCorrespondenceTypeRole'

  has_many :correspondence_types,
           -> { distinct },
           through: :correspondence_type_roles,
           dependent: :destroy

  has_many :assignments, foreign_key: :team_id

  has_many :responding_assignments,
           -> { responding },
           foreign_key: :team_id,
           class_name: 'Assignment'


  has_many :pending_accepted_assignments,
           -> { pending_accepted},
           foreign_key: :team_id,
           class_name: 'Assignment'

  has_many :cases, through: :assignments

  has_many :responding_cases,
           through: :responding_assignments,
           source: :case

  has_many :open_cases, -> { in_open_state }, through: :pending_accepted_assignments, source: :case


  scope :managing, -> { where(role: 'manager') }
  scope :approving, -> { where(role: 'approver') }
  scope :responding, -> { where(role: 'responder') }

  after_save :update_search_index


  def self.responding_for_correspondence_type(correspondence_type)
    joins(:correspondence_type_roles).where(
      'team_correspondence_type_roles.correspondence_type_id = ? and team_correspondence_type_roles.respond = ?',
      correspondence_type.id,
      true
    )
  end

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
    find_by!(code: Settings.foi_cases.default_managing_team)
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

  def child_type
    "users"
  end

  def correspondence_type_ids
    correspondence_type_roles.pluck(:correspondence_type_id)
  end

  def correspondence_type_ids=(correspondence_type_ids)
    self.correspondence_types = correspondence_type_ids
                                  .select(&:present?)
                                  .map { |id| CorrespondenceType.find(id) }
  end

  def has_active_children?
    users.any?
  end


  private

  def update_search_index
    if changed.include?('name')
      SearchIndexBuNameUpdaterJob.set(wait: 10.seconds).perform_later(self.id)
    end
  end

  def deletion_validation
    if deleted_at.present?
      if open_cases.any?
        errors.add(:base, "Unable to deactivate: this business unit has open cases")
      end

      if users.any?
        errors.add(:base, "Unable to deactivate: this business unit has team members")
      end

    end
  end

end
