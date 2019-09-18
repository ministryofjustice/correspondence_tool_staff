class Case::SAR::OffenderDecorator < Case::BaseDecorator

  def sar_response_address
    object.send_by_email? ? object.email : object.postal_address
  end

  def subject_type_display
    object.subject_type.humanize.gsub(' ', '-')
  end

  def third_party_display
    object.third_party == true ? 'Yes' : 'No'
  end

end
