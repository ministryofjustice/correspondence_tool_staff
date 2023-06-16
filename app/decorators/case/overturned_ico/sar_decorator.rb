class Case::OverturnedICO::SARDecorator < Case::OverturnedICO::BaseDecorator
  def pretty_type
    "ICO overturned (SAR)"
  end

  def requester_name_and_type
    pretty_type
  end

  def missing_info
    if object.closed?
      object.refusal_reason&.abbreviation == "sartmm" ? "yes" : "no"
    end
  end

  def sar_response_address
    object.send_by_email? ? object.email : object.postal_address
  end
end
