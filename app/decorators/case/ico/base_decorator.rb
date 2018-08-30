class Case::ICO::BaseDecorator < Case::BaseDecorator

  attr_accessor :original_case_number, :related_case_number

  def date_decision_received
    I18n.l(object.date_ico_decision_received, format: :default)
  end
end
