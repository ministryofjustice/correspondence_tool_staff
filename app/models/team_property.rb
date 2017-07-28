class TeamProperty < ActiveRecord::Base


  VALID_KEYS = %w(
    area
    lead
    can_allocate
  )

  validates :value, uniqueness: { scope: [:team_id, :key], message: "%{value} is not unique in team and key" }
  validates :key, inclusion: { in: VALID_KEYS, message: "%{value} is not a valid key" }


  scope :area, -> { where( key: 'area') }
  scope :lead, -> { where( key: 'lead') }


end
