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

        def choose_received_by(choice = 'email')
          make_radio_button_choice("case_received_by_#{choice}")
        end

        def fill_in_case_details(params={})
          kase = FactoryGirl.build :case, params

          date_received_day.set(kase.received_date.day)
          date_received_month.set(kase.received_date.month)
          date_received_year.set(kase.received_date.year)

          choose_received_by kase.received_by
          subject.set kase.subject if kase.received_by == 'email'
          full_request.set kase.message
          full_name.set kase.name
          email.set kase.email
          address.set kase.postal_address

          choose_type_of_requester(kase.requester_type)

          kase
        end
      end
    end
  end
end
