class RetentionScheduleForm < BaseFormObject
  include GovUkDateFields::ActsAsGovUkDate

  attribute :planned_destruction_date, :date

  acts_as_gov_uk_date :planned_destruction_date

  validates_presence_of :planned_destruction_date
  validate :destruction_date_after_close_date, if: :planned_destruction_date

  private

  def destruction_date_after_close_date
    unless planned_destruction_date > record.case.date_responded
      errors.add(:planned_destruction_date, :before_closure)
    end
  end

  def persist!
    record.update(
      planned_destruction_date: planned_destruction_date,
    )
  end
end
