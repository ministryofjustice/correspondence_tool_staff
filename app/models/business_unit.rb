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
  validate :at_least_one_category_role_is_present

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
  has_many :category_roles, foreign_key: :team_id, class_name: 'TeamCategoryRole'

  scope :managing, -> { where(role: 'manager') }
  scope :approving, -> { where(role: 'approver') }
  scope :responding, -> { where(role: 'responder') }


  def self.responding_for_category(category)
    joins(:category_roles).where('team_category_roles.category_id = ? and team_category_roles.respond = ?', category.id, true)
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

  # usage:
  #   set_correspondence_type_roles(category_abbreviation: 'SAR', roles: %w{ edit manage view respond })
  # #
  def set_category_roles(category_abbreviation:, roles:)
    cat = Category.find_by_abbreviation!(category_abbreviation.upcase)
    tcr = TeamCategoryRole.find_by(team_id: id, category_id: cat.id)
    if tcr.nil?
      category_roles << TeamCategoryRole.new_for(team: self, category: cat, roles: roles)
    else
      tcr.update_roles(roles)
    end
    save
  end

  # returns an array of category records
  def categories
    Category.where(id: category_roles.map(&:category_id))
  end

  def category_ids
    category_roles.map(&:category_id)
  end

  def category_ids=(category_ids)
    old_cats = categories
    new_cats = Category.where(id: category_ids)
    remove_categories(old_cats - new_cats)
    add_new_categories(new_cats - old_cats)
  end


  private
  def at_least_one_category_role_is_present
    if category_roles.empty?
      errors[:category_ids] << 'Cannot be empty'
    end
  end

  def remove_categories(cats)
    cats.each do |cat|
      category_role = category_roles.find_by(category_id: cat.id)
      category_roles.delete(category_role)
    end
  end

  def add_new_categories(cats)
    cats.each do |cat|
      set_category_roles(category_abbreviation: cat.abbreviation.downcase.to_sym, roles: category_roles_for_team)
    end
  end

  def category_roles_for_team
    case role
      when 'manager'
        [:view, :edit, :manage]
      when 'responder'
        [:view, :respond]
      when 'approver'
        [:view, :approve]
    end
  end
end
