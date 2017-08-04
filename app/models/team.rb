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
#  parent_id  :integer
#

class Team < ApplicationRecord
  validates :name, uniqueness: { scope: :type }

  acts_as_tree

  has_many :user_roles, class_name: 'TeamsUsersRole'
  has_many :users, through: :user_roles
  has_many :properties, class_name: TeamProperty
  has_many :areas, -> { area }, class_name: TeamProperty
  has_one  :team_lead, -> { lead }, class_name: TeamProperty

  scope :with_user, ->(user) {
    includes(:user_roles)
      .where(teams_users_roles: { user_id: user.id })
  }

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
end
