class Case::SAR::OffenderDecorator < Case::SAR::OffenderBaseDecorator
  include OffenderSARCaseForm

  def pretty_type
    if object.rejected?
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
    rejected_reasons.compact_blank.map { |reason|
      suffix = ": #{other_rejected_reason}" if reason == "other"
      "#{Case::SAR::Offender::REJECTED_REASONS[reason]}#{suffix}"
    }.compact.join("<br>")
  end

  def highlight_flag
    if object.flag_as_high_profile?
      h.content_tag :div, class: "#{object.type_abbreviation.downcase}-profile_flag" do
        h.content_tag(:span, "This is a ", class: "visually-hidden") + # rubocop:disable Style/StringConcatenation
          "High profile" +
          h.content_tag(:span, " case", class: "visually-hidden")
      end
    else
      ""
    end
  end
end
