module PageObjects
  module FilterMethods
    def open_filter(filter_name)
      unless __send__("has_#{filter_name}_filter_panel?", visible: true)
        tab_link_name = "#{filter_name}_tab"
        filter_tab_links.__send__(tab_link_name).click
      end
    end

    def filter_on(filter_name, *checkboxes)
      filter_panel_name = "#{filter_name}_filter_panel"
      open_filter(filter_name)

      filter_panel = __send__(filter_panel_name)

      checkboxes.each do |checkbox_name|
        filter_panel.__send__("#{checkbox_name}_checkbox").click
      end

      filter_panel.apply_filter_button.click
    end

    def remove_filter_on(filter_name, *checkboxes)
      filter_panel_name = "#{filter_name}_filter_panel"
      open_filter(filter_name)

      filter_panel = __send__(filter_panel_name)

      checkboxes.each do |checkbox_name|
        filter_panel.__send__("#{checkbox_name}_checkbox").click
      end

      filter_panel.apply_filter_button.click
    end

    def filter_on_exemptions(common: nil, all: nil)
      open_filter(:exemption)
      if common.present?
        common.each do |checkbox_code|
          checkbox_name = "#{checkbox_code}_checkbox"
          # checkbox_id = filters.exemption_filter_panel.most_used.__send__(checkbox_name)['for']
          exemption_filter_panel.most_used.__send__(checkbox_name).click
        end
      end
      if all.present?
        all.each do |checkbox_code|
          checkbox_name = "#{checkbox_code}_checkbox"
          exemption_filter_panel.exemption_all.__send__(checkbox_name).click
        end
      end
      exemption_filter_panel.apply_filter_button.click
    end

    def filter_on_deadline(preset_or_args = nil)
      if preset_or_args.respond_to? :keys
        from_date = preset_or_args.delete(:from)
        to_date   = preset_or_args.delete(:to)

        if preset_or_args.any?
          raise ArgumentError.new(
                  "unrecognised parameters: #{preset_or_args}"
                )
        end
      else
        preset = preset_or_args
      end

      self.open_filter(:deadline)
      if preset.present?
        self.deadline_filter_panel.click_on preset
      elsif from_date.present? && to_date.present?
        self.deadline_filter_panel.from_date = from_date
        self.deadline_filter_panel.to_date   = to_date
      else
        raise ArgumentError.new("please provide preset or from/to")
      end
      self.deadline_filter_panel.click_on 'Apply filter'
    end

    def filter_crumb_for(crumb_text)
      filter_crumbs.find { |crumb| crumb.text == "Remove #{crumb_text} filter." }
    end
  end
end

