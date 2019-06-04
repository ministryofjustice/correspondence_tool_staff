class Case::SAR::OffenderDecorator < Case::BaseDecorator
  include Steppable

  def steps
    %w[subject-details requester-details requested-info date-received].freeze
  end

  def get_step_partial
    step_name = current_step.split("/").first.tr('-', '_')
    "#{step_name}_step"
  end

  def sar_response_address
    object.send_by_email? ? object.email : object.postal_address
  end

  def subject_type_display
    object.subject_type.humanize
  end

  def third_party_display
    object.third_party == true ? 'Yes' : 'No'
  end

end
