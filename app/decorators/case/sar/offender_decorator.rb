class Case::SAR::OffenderDecorator < Case::BaseDecorator
  include Steppable

  def steps
    %w[subject-details requester-details requested-info date-received].freeze
  end

  def get_step_partial
    step_name = current_step.split("/").first.tr('-', '_')
    "#{step_name}_step"
  end
end
