class Report < ApplicationRecord

  validates :report_type_id,:period_start, :period_end,
            presence: true

  acts_as_gov_uk_date :period_start, :period_end,
                      validate_if: :period_within_acceptable_range?

  belongs_to :report_type

  #validates :report_data, presence: true, on: :create


   def period_within_acceptable_range?
    # if self.new_record? || received_date_changed?
      validate_period_start
      validate_period_end
    # end
  end

  def validate_period_start
    if period_start.present? && self.period_start > Date.today
      errors.add(
        :period_start,
        I18n.t('activerecord.errors.models.report.attributes.period_start.not_in_future')
      )
    elsif period_start.present? && period_end.present? && self.period_start > self.period_end
      errors.add(
        :period_start,
         I18n.t('activerecord.errors.models.report.attributes.period_start.after_end_date')
      )
    end
    errors[:period_start].any?
  end

  def validate_period_end
    if period_end.present? && self.period_end > Date.today
      errors.add(
        :period_end,
        I18n.t('activerecord.errors.models.report.attributes.period_start.not_in_future')
      )
    elsif period_start.present? && period_end.present? && self.period_start > self.period_end
      errors.add(
        :period_end,
         I18n.t('activerecord.errors.models.report.attributes.period_start.after_end_date')
      )
    end
    errors[:period_end].any?
  end

end
