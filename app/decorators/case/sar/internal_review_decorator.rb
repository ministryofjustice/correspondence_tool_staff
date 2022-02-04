class Case::SAR::InternalReviewDecorator < Case::SAR::StandardDecorator
  include Steppable

  include SarInternalReviewCaseForm

  def get_step_partial
    step_name = current_step.split("/").first.tr('-', '_')
    "#{step_name}_step"
  end

  def pretty_type
    I18n.t("helpers.label.correspondence_types.sar_internal_review_long",
           formatted_sar_ir_subtype: formatted_sar_ir_subtype)
  end

  def case_route_path
    h.step_case_sar_internal_review_index_path
  end

  def subject_type_display
    object.subject_type.humanize
  end
  
  def subject_with_original_case_reference
    if subject =~ /IR of ([0-9]+)\s-/ 
      subject
    else
      "IR of #{original_case.number} - #{subject}"
    end
  end

  def pretty_outcome_reasons
    object.outcome_reasons
      .map { |reason| reason.name }
      .join(",<br>")
      .html_safe
  end

  private

  def formatted_sar_ir_subtype
    sar_ir_subtype ? " - #{sar_ir_subtype}" : ''
  end

end
