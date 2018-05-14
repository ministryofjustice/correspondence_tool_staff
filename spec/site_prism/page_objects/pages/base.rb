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

      def make_check_box_choice(choice_id)
        if Capybara.current_driver == Capybara.javascript_driver
          find("input##{choice_id}", visible: false).trigger("click")
        else
          find("input##{choice_id}").set(true)
        end
      end

      def remove_check_box_choice(choice_id)
        if Capybara.current_driver == Capybara.javascript_driver
          find("input##{choice_id}", visible: false).trigger("click")
        else
          find("input##{choice_id}").set(false)
        end
      end

      def method_missing(method, *args)
        if method.match %r{^choose_(.+)}
          choice = args.first
          make_radio_button_choice("case_sar_#{$1}_#{choice}")
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
          row.number.text.delete('Link to case')
        end
      end

      # Upload a file to Dropzone.js
      def drop_in_dropzone(file_path:, input_name:, container_selector:)
          # Generate a uploaded request file input selector
          execute_script <<~JS
            uploadedRequestFileInput = window.$('<input/>').attr(
              { id: 'uploadedRequestFileInput',
                name: '#{input_name}',
                type:'file' }
            ).appendTo('#{container_selector}');
          JS

          wait_for_uploaded_request_file_input
          sleep 2

          # Attach the file to the uploaded request file input selector
          attach_file("uploadedRequestFileInput", file_path)

          # Add the file to a fileList array
          execute_script <<~JS
            var fileList = [uploadedRequestFileInput.get(0).files[0]];
          JS

          # Trigger the fake drop event
          execute_script <<~JS
            var e = jQuery.Event('drop', { dataTransfer : { files : [uploadedRequestFileInput.get(0).files[0]] } });
            $('.dropzone')[0].dropzone.listeners[0].events.drop(e);
          JS
      end

      def filter_on(filter_name, *checkboxes)
        tab_link_name = "#{filter_name}_tab"
        filter_tab_links.__send__(tab_link_name).click

        checkboxes.each do |checkbox_name|
          checkbox_id = "search_query_filter_#{checkbox_name}"
          make_check_box_choice(checkbox_id)
        end

        filter_panel_name = "#{filter_name}_filter_panel"
        filters.__send__(filter_panel_name).apply_filter_button.click
      end

      def remove_filter_on(filter_name, *checkboxes)
        tab_link_name = "#{filter_name}_tab"
        filter_tab_links.__send__(tab_link_name).click

        checkboxes.each do |checkbox_name|
          checkbox_id = "search_query_filter_#{checkbox_name}"
          remove_check_box_choice(checkbox_id)
        end

        filter_panel_name = "#{filter_name}_filter_panel"
        filters.__send__(filter_panel_name).apply_filter_button.click
      end
    end
  end
end
