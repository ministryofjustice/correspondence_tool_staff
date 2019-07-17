class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  after_commit :warehouse_closed_report

  def warehouse_closed_report
    'Warehousing complete'
  end
end
