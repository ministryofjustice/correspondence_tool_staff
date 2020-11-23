class Case::SAR::OffenderDecorator < Case::SAR::OffenderBaseDecorator

  include OffenderSARCaseForm

  def case_route_path
    h.step_case_sar_offender_index_path
  end

end
