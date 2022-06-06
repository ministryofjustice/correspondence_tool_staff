# == Schema Information
#
# Table name: team_properties
#
#  id         :integer          not null, primary key
#  team_id    :integer
#  key        :string
#  value      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class TeamProperty < ApplicationRecord
  include Warehousable

  VALID_KEYS = %w(
    area
    lead
    can_allocate
    role
  ).freeze
  ROLES = %w[manager responder approver].freeze

  belongs_to :team

  validates :value, uniqueness: { scope: [:team_id, :key], message: "%{value} is not unique in team and key" }
  validates :key, inclusion: { in: VALID_KEYS, message: "%{value} is not a valid key" }

  # This rather strange syntax checks that there can only be one lead property per team
  validates :key,
            if: -> (tp) { tp.key == 'lead' },
            uniqueness: { scope: :team_id, message: 'lead already exists for this team'}

  validates :value,
            if: -> (tp) { tp.key == 'role' },
            inclusion: ROLES

  scope :area, -> { where( key: 'area').order(created_at: :desc) }

  scope :lead, -> { where( key: 'lead') }
  scope :role, -> { where( key: 'role') }

end
