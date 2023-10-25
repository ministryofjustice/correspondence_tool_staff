class Case::FOI::StandardDecorator < Case::BaseDecorator
  def time_taken
    I18n.t("common.case.time_taken_result", count: deadline_calculator.time_taken)
  end
end
