module PageObjects
  module Pages
    module Cases
      class NewPage < PageObjects::Pages::Base
        set_url '/cases/new'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        element :date_received_day, '#case_received_date_dd'
        element :date_received_month, '#case_received_date_mm'
        element :date_received_year, '#case_received_date_yyyy'

        element :subject, '#case_subject'
        element :full_request, '#case_message'
        element :full_name, '#case_name'
        element :email, '#case_email'
        element :address, '#case_postal_address'

        element :type_of_requester, :xpath,
                '//fieldset[contains(.,"Type of requester")]'

        element :flag_for_disclosure_specialists, :xpath,
                '//fieldset[contains(.,"Does a disclosure specialist need to see this case")]'

        element :submit_button, '.button'

        def choose_type_of_requester(requester_type)
          make_radio_button_choice("case_requester_type_#{requester_type}")
        end

        def choose_flag_for_disclosure_specialists(choice = 'yes')
          make_radio_button_choice("case_flag_for_disclosure_specialists_#{choice}")
        end

        def choose_delivery_method(choice = 'sent_by_email')
          make_radio_button_choice("case_delivery_method_#{choice}")
        end

        def fill_in_case_details(params={})
          kase = FactoryGirl.build :case, params

          date_received_day.set(kase.received_date.day)
          date_received_month.set(kase.received_date.month)
          date_received_year.set(kase.received_date.year)

          full_name.set kase.name
          email.set kase.email
          address.set kase.postal_address
          choose_delivery_method kase.delivery_method
          subject.set kase.subject
          full_request.set kase.message if kase.delivery_method == 'sent_by_email'

          choose_type_of_requester(kase.requester_type)

          if kase.approving_teams.present?
            dacu_disclosure_team_name = Settings.foi_cases.default_clearance_team
            requires_disclosure_clearance = dacu_disclosure_team_name.in?(
              kase.approving_teams.pluck(:name)
            )
            if requires_disclosure_clearance
              choose_flag_for_disclosure_specialists 'yes'
            else
              choose_flag_for_disclosure_specialists 'no'
            end
          else
            choose_flag_for_disclosure_specialists 'no'
          end

          if kase.sent_by_post?
            kase.uploaded_request_files.each do |file|
              drop_in_dropzone(file)
            end
          end

          kase
        end

        # Upload a file to Dropzone.js
        def drop_in_dropzone(file_path)
          # Generate a uploaded request file input selector
          execute_script <<~JS
            uploadedRequestFileInput = window.$('<input/>').attr(
              { id: 'uploadedRequestFileInput',
                name: 'case[uploaded_request_files][]',
                type:'file' }
            ).appendTo($('#delivery-method-fields'));
          JS

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
      end
    end
  end
end
