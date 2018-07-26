# == Schema Information
#
# Table name: report_types
#
#  id            :integer          not null, primary key
#  abbr          :string           not null
#  full_name     :string           not null
#  class_name    :string           not null
#  custom_report :boolean          default(FALSE)
#  seq_id        :integer          not null
#  foi           :boolean          default(FALSE)
#  sar           :boolean          default(FALSE)
#

class ReportType < ApplicationRecord
  has_many :reports

  scope :custom, -> { where( custom_report: true ) }
  scope :foi, -> { where( foi: true ) }
  scope :sar, -> { where( sar: true ) }

  def class_constant
    class_name.constantize
  end

  def filename
    "#{class_name.to_s.underscore.sub('stats/', '')}.csv"
  end
end
