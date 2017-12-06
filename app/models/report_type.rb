class ReportType < ApplicationRecord
  has_many :reports

  scope :custom, -> { where( custom_report: true ) }

end
