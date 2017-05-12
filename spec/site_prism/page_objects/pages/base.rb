module PageObjects
  module Pages
    class Base < SitePrism::Page
      def make_radio_button_choice(choice_id)
        if Capybara.current_driver == Capybara.javascript_driver
          find("input##{choice_id}", visible: false).trigger("click")
        else
          find("input##{choice_id}").set(true)
        end
      end
    end
  end
end
