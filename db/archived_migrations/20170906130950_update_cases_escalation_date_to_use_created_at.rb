class UpdateCasesEscalationDateToUseCreatedAt < ActiveRecord::Migration[5.0]
  class Case < ApplicationRecord
    belongs_to :category, optional: false

    jsonb_accessor :properties,
                   escalation_deadline: :date,
                   internal_deadline: :date,
                   external_deadline: :date

    self.inheritance_column = :_type_not_used
  end

  class Category < ApplicationRecord
  end

  def up
    cases = Case.all
    cases.each do |kase|
      new_escalation_date(kase)
    end
  end

  def down
    cases = Case.all
    cases.each do |kase|
      old_escalation_date(kase)
    end
  end

private

  def new_escalation_date(kase)
    kase.escalation_deadline = calculate_date(kase, kase.created_at.to_date)
    kase.save!
  end

  def old_escalation_date(kase)
    kase.escalation_deadline = calculate_date(kase, kase.received_date)
    kase.save!
  end

  def calculate_date(kase, date_to_use)
    days_after_day_one = kase.category.escalation_time_limit - 1
    start_date(date_to_use) + days_after_day_one.working.days
  end

  def start_date(received_date)
    date = received_date + 1
    date += 1 until date.working_day?
    date
  end
end
