class Case::ICO::BaseDecorator < Case::BaseDecorator

  attr_accessor :related_case_number

  def formatted_date_ico_decision_received
    I18n.l(object.date_ico_decision_received, format: :default)
  end

  def pretty_ico_decision
    if object.ico_decision.present?
      "#{object.ico_decision.capitalize} by ICO"
    else
      ""
    end
  end

end
