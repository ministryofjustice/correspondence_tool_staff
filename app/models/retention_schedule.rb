class RetentionSchedule < ApplicationRecord
  include AASM

  validates :case, :planned_destruction_date, :status, presence: true

  # this should change to Case::Base
  # as this retention_schedule is expanded
  # to other / all case types
  belongs_to :case,
             class_name: 'Case::SAR::Offender'

  aasm column: 'state', logger: Rails.logger do
    state :not_set, initial: true, display: 'Not set'
    state :retain, display: 'Retain'
    state :review, display: 'Review'
    state :to_be_destroyed, display: 'Destroy'
    state :destroyed, display: 'Anonymised'
    
    event :mark_for_retention do
      transitions from: [:not_set, :review, :to_be_destroyed], to: :retain
    end

    event :mark_for_review do
      transitions from: [:not_set, :retain, :to_be_destroyed], to: :review
    end

    event :mark_for_destruction do
      transitions from: [:not_set, :retain, :review], to: :to_be_destroyed
    end

    event :unlist do
      transitions from: [:retain], to: :not_set
    end

    event :final_destruction do
      transitions from: [:to_be_destroyed], to: :destroyed
    end
  end

  class << self
    def common_date_viewable_from_range
      viewable_from = Settings.retention_timings.common.viewable_from
      viewable_from.months.ago..Time.current.to_date
    end
  end
end
