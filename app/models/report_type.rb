# == Schema Information
#
# Table name: report_types
#
#  id                       :integer          not null, primary key
#  abbr                     :string           not null
#  full_name                :string           not null
#  class_name               :string           not null
#  custom_report            :boolean          default(FALSE)
#  seq_id                   :integer          not null
#  foi                      :boolean          default(FALSE)
#  sar                      :boolean          default(FALSE)
#  standard_report          :boolean          default(FALSE), not null
#  default_reporting_period :string           default("year_to_date")
#  etl                      :boolean          default(FALSE)

class ReportType < ApplicationRecord

  VALID_DEFAULT_REPORTING_PERIODS = %w{
                                        year_to_date
                                        quarter_to_date
                                        last_quarter
                                        last_month
                                      }.freeze

  has_many :reports

  scope :custom,   -> { where( custom_report: true ) }
  scope :standard, -> { where( standard_report: true ) }
  scope :foi, -> { where( foi: true ) }
  scope :sar, -> { where( sar: true ) }
  scope :offender_sar, -> { where( offender_sar: true ) }
  scope :offender_sar_complaint, -> { where( offender_sar_complaint: true ) }
  scope :closed_cases_report, -> { where(abbr: 'R007') }

  validates :default_reporting_period, presence: true, inclusion: { in: VALID_DEFAULT_REPORTING_PERIODS }


  def class_constant
    @_class_constant ||= class_name.constantize
  end

  def filename(extension)
    "#{class_name.to_s.underscore.sub('stats/', '')}.#{extension}"
  end

  def self.method_missing(meth, *args)
    if meth.to_s =~ /^r\d\d\d$/
      self.find_by!(abbr: meth.to_s.upcase)
    else
      super
    end
  end

  def self.respond_to_missing?(meth, include_private = false)
    meth.to_s =~ /^r\d\d\d$/ || super
  end

  def default_reporting_period_text
    ReportingPeriod::Calculator.build(period_name: default_reporting_period).to_s
  end

  def file_extension
    class_constant.report_format
  end

  def description
    class_constant.description
  end

end
