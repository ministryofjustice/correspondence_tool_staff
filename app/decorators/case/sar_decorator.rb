class Case::SARDecorator < Case::BaseDecorator
  def missing_info
    if object.closed?
      object.refusal_reason&.abbreviation == 'tmm' ? 'yes' : 'no'
    end
  end

  def subject_type
    object.subject_type.humanize
  end


  def third_party
    object.third_party ? 'Yes' : 'No'
  end

  def sar_response_address
    object.send_by_email? ? object.email : object.postal_address
  end
end
