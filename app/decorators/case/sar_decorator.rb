class Case::SARDecorator < Case::BaseDecorator
  def missing_info
    if object.closed?
      object.refusal_reason&.abbreviation == 'tmm' ? 'yes' : 'no'
    end
  end

  def sar_response_address
    object.send_by_email? ? object.email : object.postal_address
  end
end
