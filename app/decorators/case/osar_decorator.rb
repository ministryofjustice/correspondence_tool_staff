class Case::OSARDecorator < Case::BaseDecorator
  def get_step_partial
    step_name = current_step.split("/").first.tr('-', '_')
    "#{step_name}_step"
  end
end
