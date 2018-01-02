# == Schema Information
#
# Table name: reports
#
#  id             :integer          not null, primary key
#  report_type_id :integer          not null
#  period_start   :date
#  period_end     :date
#  report_data    :binary
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Report < ApplicationRecord

  validates :report_type_id, presence: true

  acts_as_gov_uk_date :period_start, :period_end,
                      validate_if: :period_within_acceptable_range?

  belongs_to :report_type


  private

  def period_within_acceptable_range?
    validate_period_start
    validate_period_end
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
    end
    errors[:period_end].any?
  end

end
