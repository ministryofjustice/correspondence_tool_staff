class CorrespondenceTypeDecorator < Draper::Decorator
  delegate_all

  def pretty_name
    type_name = I18n.t("helpers.label.correspondence_types.#{object.abbreviation.downcase}")
    "#{type_name} - #{object.name}"
  end
end
