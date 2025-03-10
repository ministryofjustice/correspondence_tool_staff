class Case::ICO::BaseDecorator < Case::BaseDecorator
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  attr_accessor :related_case_number

  def formatted_date_ico_decision_received
    I18n.l(object.date_ico_decision_received, format: :default)
  end

  def pretty_ico_decision
    decision = ""

    if object.ico_decision.present?
      decision += "#{object.ico_decision.capitalize} by ICO"
    end

    if object.try(:sar_complaint_outcome).present?
      decision += if object.sar_complaint_outcome == "other_outcome"
                    content_tag(:div) { object.other_sar_complaint_outcome_note }
                  else
                    content_tag(:div) { I18n.t("helpers.label.ico.sar_complaint_outcome.#{object.sar_complaint_outcome}") }
                  end
    end

    decision
  end

  def original_internal_deadline
    if object.original_internal_deadline.present?
      I18n.l(object.original_internal_deadline, format: :default)
    end
  end

  def original_external_deadline
    if object.original_external_deadline.present?
      I18n.l(object.original_external_deadline, format: :default)
    end
  end

  def original_date_responded
    if object.original_date_responded.present?
      I18n.l(object.original_date_responded, format: :default)
    end
  end
end
