class Case::OverturnedICO::FOIDecorator < Case::OverturnedICO::BaseDecorator
  def pretty_type
    "ICO overturned (FOI)"
  end

  def requester_name_and_type
    pretty_type
  end

  def time_taken
    I18n.t("common.case.time_taken_result", count: deadline_calculator.time_taken)
  end
end
