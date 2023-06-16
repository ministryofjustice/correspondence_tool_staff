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

  def original_internal_deadline
    if object.original_internal_deadline.present?
      I18n.l(object.original_internal_deadline, format: :default)
    end
  end

  def original_external_deadline
    if object.original_external_deadline.present?
      I18n.l(object.original_external_deadline, format: :default)
    end
  end

  def original_date_responded
    if object.original_date_responded.present?
      I18n.l(object.original_date_responded, format: :default)
    end
  end
end
