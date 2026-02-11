require "site_prism"
module PageObjects
  module Pages
    class Base < SitePrism::Page
      def make_radio_button_choice(choice_id)
        if Capybara.current_driver == Capybara.javascript_driver
          find("input##{choice_id}", visible: false).click
        else
          find("input##{choice_id}").set(true)
        end
      end

      def make_check_box_choice(choice_id)
        unless find("input##{choice_id}", visible: false).checked?
          if Capybara.current_driver == Capybara.javascript_driver
            find("input##{choice_id}", visible: false).click
          else
            find("input##{choice_id}").set(true)
          end
        end
      end

      def remove_check_box_choice(choice_id)
        if find("input##{choice_id}", visible: false).checked?
          if Capybara.current_driver == Capybara.javascript_driver
            find("input##{choice_id}", visible: false).click
          else
            find("input##{choice_id}").set(false)
          end
        end
      end

      def method_missing(method, *args)
        if method.match %r{^choose_(.+)}
          choice = args.first
          make_radio_button_choice("sar_#{::Regexp.last_match(1)}_#{choice}")
        else
          super
        end
      end

      def respond_to_missing?(method, _include_private = false)
        method.match(%r{^choose_.+}) ? true : super
      end

      # for use on pages with a case list section
      def case_numbers
        case_list.map do |row|
          row.number.text.delete("Link to case").delete("\n")
        end
      end
    end
  end
end
