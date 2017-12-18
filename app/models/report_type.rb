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
#

class ReportType < ApplicationRecord
  has_many :reports

  scope :custom, -> { where( custom_report: true ) }

  def class_constant
    class_name.constantize
  end
end
