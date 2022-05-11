class UpdateCasesEscalationDateToUseCreatedAt < ActiveRecord::Migration[5.0]
  class Case < ActiveRecord::Base
     belongs_to :category, required: true

     jsonb_accessor :properties,
                    escalation_deadline: :date,
                    internal_deadline: :date,
                    external_deadline: :date

     self.inheritance_column = :_type_not_used
  end

  class Category < ActiveRecord::Base
  end

  def up
    cases = Case.all
    cases.each do | kase |
      new_escalation_date(kase)
    end
  end

  def down
    cases = Case.all
    cases.each do | kase |
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
    days_after_day_one.business_days.after(start_date(date_to_use))
  end

  def start_date(received_date)
    date = received_date + 1
    date += 1 until date.workday?
    date
  end
end

