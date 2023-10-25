class Case::SAR::StandardDecorator < Case::BaseDecorator
  def missing_info
    if object.closed?
      object.refusal_reason&.abbreviation == "sartmm" ? "yes" : "no"
    end
  end

  def sar_response_address
    object.send_by_email? ? object.email : object.postal_address
  end

  def subject_type_display
    object.subject_type.humanize
  end

  def third_party_display
    object.third_party == true ? "Yes" : "No"
  end

  def time_taken
    calendar_days_taken
  end

  def request_methods_sorted
    Case::SAR::Standard.request_methods.keys.sort
  end

  def request_methods_for_display
    request_methods_sorted - %w[unknown]
  end
end
