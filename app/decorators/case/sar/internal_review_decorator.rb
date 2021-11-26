class Case::SAR::InternalReviewDecorator < Case::SAR::StandardDecorator
  include Steppable

  include SarInternalReviewCaseForm

  def get_step_partial
    step_name = current_step.split("/").first.tr('-', '_')
    "#{step_name}_step"
  end

  def pretty_type
    I18n.t("helpers.label.correspondence_types.sar_internal_review_long")
  end

  def case_route_path
    h.step_case_sar_internal_review_index_path
  end

  def subject_type_display
    object.subject_type.humanize
  end
end
