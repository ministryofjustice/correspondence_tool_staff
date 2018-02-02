class Case::SARDecorator < Case::BaseDecorator

  def subject_type
    object.subject_type.humanize
  end


  def third_party
    object.third_party ? 'Yes' : 'No'
  end

  def sar_response_address
    object.email.present? ? object.email : object.postal_address
  end
end
