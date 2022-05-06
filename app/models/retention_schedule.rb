class RetentionSchedule < ApplicationRecord
  include AASM

  validates_presence_of(:case)
  validates_presence_of(:planned_erasure_date)

  # this should change to Case::Base
  # as this retention_schedule is expanded
  # to other / all case types
  belongs_to :case,
             foreign_key: :case_id,
             class_name: 'Case::SAR::Offender'

  aasm column: 'state', logger: Rails.logger do
    state :not_set, initial: true, display: 'Not set'
    state :retain, display: 'Retain'
    state :review, display: 'Review'
    state :destroy, display: 'Destroy'
    state :destroyed, display: 'Anonymised'
    
    event :mark_for_retention do
      transitions from: [:not_set, :review, :destroy], to: :retain
    end

    event :mark_for_review do
      transitions from: [:not_set, :retain, :destroy], to: :review
    end

    event :mark_for_destruction do
      transitions from: [:not_set, :retain, :review], to: :destroy
    end

    event :unlist do
      transitions from: [:retain], to: :not_set
    end

    event :final_destruction do
      transitions from: [:destroy], to: :destroyed
    end
  end

  class << self
    def common_date_viewable_from_range
      viewable_from = Settings.retention_timings.common.viewable_from
      viewable_from.months.ago..Date.today
    end
  end
end
