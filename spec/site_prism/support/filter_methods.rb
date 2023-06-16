module PageObjects
  module FilterMethods
    def open_filter(filter_name)
      unless __send__("has_filter_cases_accordion?", visible: true)
        case_filters.filter_cases_link.click
      end
      unless __send__("has_filter_#{filter_name}_content?", visible: true)
        link_name = "filter_#{filter_name}_link"
        case_filters.__send__(link_name).click
      end
    end

    def filter_on(filter_name, *checkboxes)
      filter_panel_name = "filter_#{filter_name}_content"
      open_filter(filter_name)

      filter_panel = __send__(filter_panel_name)

      checkboxes.each do |checkbox_name|
        filter_panel.__send__("#{checkbox_name}_checkbox").click
      end

      case_filters.apply_filters_button.click
    end

    def remove_filter_on(filter_name, *checkboxes)
      filter_panel_name = "filter_#{filter_name}_content"
      open_filter(filter_name)

      filter_panel = __send__(filter_panel_name)

      checkboxes.each do |checkbox_name|
        filter_panel.__send__("#{checkbox_name}_checkbox").click
      end

      case_filters.apply_filters_button.click
    end

    def filter_on_exemptions(common: nil, all: nil)
      open_filter(:exemption)
      if common.present?
        common.each do |checkbox_code|
          checkbox_name = "#{checkbox_code}_checkbox"
          # checkbox_id = filters.exemption_filter_panel.most_used.__send__(checkbox_name)['for']
          filter_exemption_content.most_used.__send__(checkbox_name).click
        end
      end
      if all.present?
        all.each do |checkbox_code|
          checkbox_name = "#{checkbox_code}_checkbox"
          filter_exemption_content.exemption_all.__send__(checkbox_name).click
        end
      end
      case_filters.apply_filters_button.click
    end

    def filter_on_deadline(preset_or_args = nil)
      if preset_or_args.respond_to? :keys
        from_date = preset_or_args.delete(:from)
        to_date   = preset_or_args.delete(:to)

        if preset_or_args.any?
          raise ArgumentError, "unrecognised parameters: #{preset_or_args}"
        end
      else
        preset = preset_or_args
      end

      open_filter(:external_deadline)
      if preset.present?
        filter_external_deadline_content.click_on preset
      elsif from_date.present? && to_date.present?
        filter_external_deadline_content.from_date = from_date
        filter_external_deadline_content.to_date   = to_date
      else
        raise ArgumentError, "please provide preset or from/to"
      end
      case_filters.apply_filters_button.click
    end

    def filter_crumb_for(crumb_text)
      Capybara.ignore_hidden_elements = false
      result = filter_crumbs.find { |crumb| crumb.text == "Remove #{crumb_text} filter." }
      Capybara.ignore_hidden_elements = true
      result
    end
  end
end
