module GovukElementsErrorsExtHelper

  def error_summary_list object
    content_tag(:ul, class: 'error-summary-list') do
      messages = error_summary_messages(object)
      messages.flatten.join('').html_safe
    end
  end

  def error_summary_messages object
    object.errors.attribute_names.map do |attribute|
      error_summary_message object, attribute
    end
  end

  def error_summary_message object, attribute
    messages = object.errors.full_messages_for attribute
    messages.map do |message|
      object_prefixes = object_prefixes object
      link = link_to_error(object_prefixes, attribute)
      message.sub! default_label(attribute), localized_label(object_prefixes, attribute)
      content_tag(:li, content_tag(:a, message, href: link))
    end
  end

  def object_prefixes object
    [underscore_name(object)]
  end

end

module GovukElementsErrorsHelper
  singleton_class.prepend GovukElementsErrorsExtHelper
end
