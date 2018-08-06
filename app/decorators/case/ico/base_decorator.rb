class Case::ICO::BaseDecorator < Case::BaseDecorator

  attr_accessor :original_case_number, :related_case_number

  attr_accessor :ico_decision, :date_ico_decision_received
  attr_accessor :date_ico_decision_received_dd
  attr_accessor :date_ico_decision_received_mm
  attr_accessor :date_ico_decision_received_yyyy

end
