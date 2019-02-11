class Case::SARDecorator < Case::BaseDecorator
  def missing_info
    if object.closed?
      object.refusal_reason&.abbreviation == 'sartmm' ? 'yes' : 'no'
    end
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
