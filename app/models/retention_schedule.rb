class RetentionSchedule < ApplicationRecord

  validates_presence_of(:case)
  validates_presence_of(:planned_erasure_date)
  validates_presence_of(:status)

  # this should change to Case::Base
  # as this retention_schedule is expanded
  # to other / all case types
  belongs_to :case,
             foreign_key: :case_id,
             class_name: 'Case::SAR::Offender'

  enum status: { 
    review: "review", 
    retain: "retain", 
    erasable: "erasable", 
    erased: "erased", 
    not_set: "not_set" 
  }, _default: "not_set"

end
