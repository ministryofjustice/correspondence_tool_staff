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

class Team < ApplicationRecord
  include Warehousable

  validates :name, uniqueness: { scope: :type }
  validate :valid_role
  validate :deletion_validation

  DEACTIVATED_LABEL = '[DEACTIVATED]'.freeze

  acts_as_tree

  has_paper_trail ignore: [:created_at, :updated_at]

  has_many :user_roles, class_name: 'TeamsUsersRole'
  has_many :users, -> { order(:full_name) }, through: :user_roles
  has_many :properties, class_name: 'TeamProperty', dependent: :delete_all
  has_many :areas, -> { area }, class_name: 'TeamProperty'

  # This can be eager loaded using includes
  has_one :team_leader,
          -> { lead },
          class_name: TeamProperty.to_s

  has_one :old_team, class_name: 'Team', foreign_key: :moved_to_unit_id
  belongs_to :moved_to_unit, class_name: 'Team', optional: true

  scope :with_user, ->(user) {
    includes(:user_roles)
      .where(teams_users_roles: { user_id: user.id })
      .order(:name)
  }

  scope :active, ->{ where(deleted_at: nil)}

  def self.hierarchy
    result_set = []
    BusinessGroup.order(:name).each do |bg|
      result_set << bg
      bg.directorates.order(:name).each do |dir|
        result_set << dir
        dir.business_units.order(:name).each { |bu| result_set << bu }
      end
    end
    result_set
  end

  def valid_role
    unless role.blank?
      errors.add(:role, :present)
    end
  end

  def can_allocate?(correspondence_type)
    properties.where(
      key: 'can_allocate',
      value: correspondence_type.abbreviation
    ).any?
  end

  def enable_allocation(correspondence_type)
    unless can_allocate?(correspondence_type)
      properties << TeamProperty.create!(key: 'can_allocate',
                                         value: correspondence_type.abbreviation)
    end
  end

  def disable_allocation(correspondence_type)
    properties.where(
      key: 'can_allocate',
      value: correspondence_type.abbreviation
    ).delete_all
  end

  def self.allocatable(correspondence_type)
    Team.joins(:properties).where(team_properties: {
                                    key: 'can_allocate',
                                    value: correspondence_type.abbreviation
                                  })
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

  def team_leader_name
    team_leader&.value || ''
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

  def has_active_children?
    children.active.any?
  end

  def active?
    deleted_at.nil?
  end

  def inactive?
    !active?
  end

  # @note (Mohammed Seedat 2019-04-03) Original Team Name workaround
  #   Team table has no way of storing historical data. On deactivation, the
  #   Team's name is changed - name therefore stores deletion information.
  #   To retrieve the Team name without any of the  deactivation information
  #   we require this string replacement workaround.
  #
  # @todo (Mohammed Seedat 2019-04-03) Investigate implementation further
  #
  # @example '[DEACTIVATED] The Avengers @(2019-01-02 12:32)'
  def original_team_name
    name.remove(DEACTIVATED_LABEL, /@\((.)*\)/).strip
  end

  def deactivated
    deleted_at&.strftime("%d/%m/%Y") || ''
  end

  def moved
    moved_to_unit&.parent&.name || ''
  end

  private

  # This method applies to Business Groups and Directorates only.
  # It is overridden in BusinessUnit.
  def deletion_validation
    if deleted_at.present? && has_active_children?
      errors.add(:base, 'Unable to delete team: team still has active children')
    end
  end
end
