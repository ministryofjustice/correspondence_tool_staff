class RetentionScheduleForm < BaseFormObject
  include GovUkDateFields::ActsAsGovUkDate

  attribute :planned_destruction_date, :date
  attribute :state, :string

  acts_as_gov_uk_date :planned_destruction_date

  validates_presence_of :planned_destruction_date
  validate :destruction_date_after_close_date, if: :planned_destruction_date

  validates_inclusion_of :state, in: :state_choices
  validate :state_is_not_anonymised

  def state_choices
    allowed_states.map(&:to_s)
  end

private

  # If the retention schedule has progressed already to any state other than the
  # initial `not_set`, we don't allow reverting back to the initial state, so we
  # remove this state from the available choices.
  #
  # Additionally, we don't handle the anonymisation through this form, so we also
  # remove the final state.
  #
  def allowed_states
    RetentionSchedule.state_names.tap do |states|
      states.delete(RetentionSchedule::STATE_ANONYMISED)
      states.delete(RetentionSchedule::STATE_NOT_SET) unless record.not_set?
    end
  end

  # If the case has been anonymised, we can't go back to any previous state.
  # Although change links will be disabled, a malicious request could be crafted.
  def state_is_not_anonymised
    errors.add(:state, :forbidden) if record.anonymised?
  end

  def destruction_date_after_close_date
    unless planned_destruction_date > record.case.date_responded
      errors.add(:planned_destruction_date, :before_closure)
    end
  end
end
