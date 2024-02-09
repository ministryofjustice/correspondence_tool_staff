class Case::SAR::OffenderDecorator < Case::SAR::OffenderBaseDecorator
  include OffenderSARCaseForm

  def pretty_type
    I18n.t("helpers.label.correspondence_types.offender_sar")
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

  def rejected_reasons_description(reason_key)
    REJECTED_REASONS.map { |reason| reason[reason_key] }.compact.first
  end
end

