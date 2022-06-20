class RetentionSchedule < ApplicationRecord
  include AASM

  validates_presence_of(:case)
  validates_presence_of(:planned_destruction_date)

  # this should change to Case::Base
  # as this retention_schedule is expanded
  # to other / all case types
  belongs_to :case,
             foreign_key: :case_id,
             class_name: 'Case::SAR::Offender'

  # Event `anonymise` will update the `erasure_date` automatically.
  # We alias it because for this update to magically work, the date attribute
  # should have followed the convention `[new_state]_at` instead.
  alias_attribute :anonymised_at, :erasure_date

  aasm column: 'state', timestamps: true, logger: Rails.logger do
    state :not_set, initial: true, display: 'Not set'
    state :retain, display: 'Retain'
    state :review, display: 'Review'
    state :to_be_anonymised, display: 'Destroy'
    state :anonymised, display: 'Anonymised'
    
    event :mark_for_retention do
      transitions from: [:not_set, :review, :to_be_anonymised], to: :retain
    end

    event :mark_for_review do
      transitions from: [:not_set, :retain, :to_be_anonymised], to: :review
    end

    event :mark_for_anonymisation do
      transitions from: [:not_set, :retain, :review], to: :to_be_anonymised
    end

    event :unlist do
      transitions from: [:retain], to: :not_set
    end

    event :anonymise do
      transitions from: [:to_be_anonymised], to: :anonymised
    end
  end

  def human_state
    aasm.human_state
  end

  class << self
    def common_date_viewable_from_range
      viewable_from = Settings.retention_timings.common.viewable_from
      (..(Date.today + viewable_from.months))
    end

    def erasable_cases_viewable_range
      (..Date.today)
    end

    def triagable_destory_cases_range
      ((Date.today + 1)..)
    end

    def states_map
      aasm.states.to_h { |state| [state.name, state.display_name] }
    end

    def state_names
      aasm.states.map(&:name)
    end
  end
end
