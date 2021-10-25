class Case::SAR::OffenderDecorator < Case::SAR::OffenderBaseDecorator

  include OffenderSARCaseForm

  def pretty_type
    I18n.t("helpers.label.correspondence_types.offender_sar")
  end

  def case_route_path
    h.step_case_sar_offender_index_path
  end

end
