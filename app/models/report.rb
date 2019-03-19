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

# Because run_and_update! needs to generate CSV
require 'csv'

class Report < ApplicationRecord

  validates_presence_of :report_type_id,
                        :period_start,
                        :period_end

  acts_as_gov_uk_date :period_start, :period_end,
                      validate_if: :period_within_acceptable_range?

  belongs_to :report_type
  attr_accessor :correspondence_type

  def self.last_by_abbr(abbr)
    report_type = ReportType.find_by_abbr(abbr)
    where(report_type_id: report_type.id).order(id: :desc).limit(1).singular
  end

  def report_type_abbr=(abbr)
    self.report_type = ReportType.find_by(abbr: abbr)
  end

  def run(*args)
    report_service = report_type.class_constant.new(*args)
    report_service.run
    report_service
  end

  def run_and_update!(*args)
    report_service = run(*args)

    update! report_data: generate_csv(report_service),
            period_start: report_service.period_start,
            period_end: report_service.period_end
  end

  def trim_older_reports
    Report
      .where('id < ? and report_type_id = ?', self.id, self.report_type_id)
      .destroy_all
  end

  def xlsx?
    report_type.class_constant.xlsx?
  end

  private

  def generate_csv(report_service)
    CSV.generate(headers: true) do |csv_generator|
      report_service.to_csv.each do |csv_row|
        csv_generator << csv_row.map(&:value)
      end
    end
  end

  def period_within_acceptable_range?
    i18n_prefix = 'activerecord.errors.models.report.attributes'
    if period_in_the_future?(period_start)
      errors.add :period_start,
                 I18n.t("#{i18n_prefix}.period_start.in_future")
    elsif period_in_the_future?(period_end)
      errors.add :period_end,
                 I18n.t("#{i18n_prefix}.period_end.in_future")
    elsif period_end_before_period_start?(period_start, period_end)
      errors.add :period_end,
                 I18n.t("#{i18n_prefix}.period_end.before_start_date")
    end
    errors[:period_start].any?
  end

  def period_in_the_future?(period_date)
    period_date.present? && period_date > Date.today
  end

  def period_end_before_period_start?(period_start, period_end)
    period_start.present? &&
      period_end.present? &&
      period_start > period_end
  end
end
