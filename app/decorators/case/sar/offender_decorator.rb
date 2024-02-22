class Case::SAR::OffenderDecorator < Case::SAR::OffenderBaseDecorator
  include OffenderSARCaseForm

  def pretty_type
    if object.current_state == "rejected"
      I18n.t("helpers.label.correspondence_types.rejected_offender_sar")
    else
      I18n.t("helpers.label.correspondence_types.offender_sar")
    end
  end

  def case_route_path
    h.step_case_sar_offender_index_path
  end

  def request_methods_sorted
    Case::SAR::Offender.request_methods.keys.sort
  end

  def request_methods_for_display
    request_methods_sorted - %w[unknown]
  end

  def rejected_reasons_descriptions
    rejected_reasons.map { |reason|
      Case::SAR::Offender::REJECTED_REASONS[reason]
    }.append(other_rejected_reason).compact.join("<br>")
  end
end
