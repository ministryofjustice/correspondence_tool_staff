# Cannot upgrade govuk_elements_form_builder gem to v1.3.1 yet due to
# compatibility issues with govuk_frontend_toolkit - however need the ability to
# set custom legend text for fieldsets for Stop the Clock functionality.
# TODO: Remove on upgrade CDPTKAN-XXX
module GovukElementsFormBuilder
  class FormBuilder < ActionView::Helpers::FormBuilder
    def fieldset_legend(attribute, options)
      legend_text = options.fetch(:legend_options, {}).delete(:text)

      legend = content_tag(:legend) do
        tags = [content_tag(
          :span,
          legend_text || fieldset_text(attribute),
          merge_attributes(options[:legend_options], default: { class: "form-label-bold" }),
        )]

        if error_for? attribute
          tags << content_tag(
            :span,
            error_full_message_for(attribute),
            class: "error-message",
          )
        end

        hint = hint_text attribute
        tags << content_tag(:span, hint, class: "form-hint") if hint

        safe_join tags
      end
      legend.html_safe
    end
  end
end
