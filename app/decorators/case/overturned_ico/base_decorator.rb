class Case::OverturnedIco::BaseDecorator < Case::BaseDecorator
  def internal_deadline
    I18n.l(object.internal_deadline, format: :default)
  end

  def formatted_date_ico_decision_received
    I18n.l(object.date_ico_decision_received, format: :default)
  end

  def original_case_description
    "#{object.original_ico_appeal.decorate.pretty_type} #{object.original_ico_appeal.number}"
  end
end
