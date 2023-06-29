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
#  guid           :string
#  properties     :jsonb
#

class Report < ApplicationRecord
  jsonb_accessor :properties,
                 background_job: :boolean,
                 status: :string,
                 job_ids: [:string, { array: true, default: [] }],
                 filename: :string,
                 persist_results: :boolean,
                 user_id: :integer,
                 report_format: :string

  validates :report_type_id, :period_start, :period_end, presence: true

  acts_as_gov_uk_date :period_start, :period_end, validate_if: :period_within_acceptable_range?

  belongs_to :report_type

  attr_accessor :correspondence_type

  def self.last_by_abbr(abbr)
    report_type = ReportType.find_by(abbr:)
    where(report_type_id: report_type.id).order(id: :desc).limit(1).singular
  end

  def report_type_abbr=(abbr)
    self.report_type = ReportType.find_by(abbr:)
  end

  def run(report_guid: SecureRandom.uuid, **args)
    report_service = report_type.class_constant.new(**args)
    report_service.run(report_guid:)
    report_service
  end

  def run_and_update!(**args)
    self.guid = SecureRandom.uuid
    report_service = run(report_guid: guid, **args)
    if report_service.background_job?
      self.status = report_service.status
      self.job_ids = report_service.job_ids
    else
      self.report_data = report_service.results.to_json
    end
    self.background_job = report_service.background_job?
    self.filename = report_service.filename
    self.user_id = report_service.user.nil? ? 0 : report_service.user.id
    self.report_format = report_service.report_format
    self.period_start = report_service.period_start
    self.period_end = report_service.period_end
    self.persist_results = report_service.persist_results?
    save! if report_service.persist_results?
  end

  def to_csv
    report_service = report_type.class_constant.new(
      period_start:,
      period_end:,
    )
    report_service.set_results(JSON.parse(report_data, symbolize_names: true))
    report_service.to_csv
  end

  def report_details
    if background_job?
      report_service = report_type.class_constant.new(
        period_start:,
        period_end:,
      )
      data = report_service.report_details(self)
    else
      data = report_data
    end

    [data, filename]
  end

  def ready?
    status == Stats::BaseReport::COMPLETE
  end

  def persist_results?
    persist_results
  end

  # ETL (Extract Transform Load) based reports are generated using
  # the Warehouse, and therefore require processing before making
  # available for download
  def etl?
    report_type&.etl?
  end

  def background_job?
    background_job
  end

private

  def period_within_acceptable_range?
    i18n_prefix = "activerecord.errors.models.report.attributes"
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
    period_date.present? && period_date > Time.zone.today
  end

  def period_end_before_period_start?(period_start, period_end)
    period_start.present? &&
      period_end.present? &&
      period_start > period_end
  end
end
