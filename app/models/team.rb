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

class Team < ApplicationRecord
  validates :name, uniqueness: { scope: :type }

  validate :valid_role

  acts_as_tree

  has_many :user_roles, class_name: 'TeamsUsersRole'
  has_many :users, -> { order(:full_name) }, through: :user_roles
  has_many :properties, class_name: TeamProperty, :dependent => :delete_all
  has_many :areas, -> { area }, class_name: TeamProperty

  scope :with_user, ->(user) {
    includes(:user_roles)
      .where(teams_users_roles: { user_id: user.id })
      .order(:name)
  }

  def valid_role
    unless role.blank?
      errors.add(:role, :present)
    end
  end

  def can_allocate?(category)
    properties.where(key: 'can_allocate', value: category.abbreviation).any?
  end

  def enable_allocation(category)
    unless can_allocate?(category)
      properties << TeamProperty.create!(key: 'can_allocate', value: category.abbreviation)
    end
  end

  def disable_allocation(category)
    properties.where(key: 'can_allocate', value: category.abbreviation).delete_all
  end

  def self.allocatable(category)
    Team.joins(:properties).where(team_properties: { key: 'can_allocate', value: category.abbreviation })
  end

  def policy_class
    TeamPolicy
  end

  def pretty_type
    I18n.t("team_types.#{type.underscore}")
  end

  def pretty_team_lead_title
    I18n.t("team_lead_types.#{type.underscore}")
  end

  def team_lead
    properties.lead.singular_or_nil&.value || ''
  end

  def team_lead=(name)
    if properties.lead.exists?
      properties.lead.singular.update value: name
    else
      TeamProperty.new(key: 'lead', value: name).tap do |property|
        properties << property
      end
    end
  end

  def active_users
    users.where(deleted_at: nil)
  end
end
