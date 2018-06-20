module PageObjects
  module Pages
    module Cases
      module New
        class FOIPage < PageObjects::Pages::Base
          set_url '/cases/new/foi'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'
          element :case_type, :xpath,
                  '//fieldset[contains(.,"Type")]'

          element :date_received_day, '#case_foi_received_date_dd'
          element :date_received_month, '#case_foi_received_date_mm'
          element :date_received_year, '#case_foi_received_date_yyyy'

          element :subject, '#case_foi_subject'
          element :full_request, '#case_foi_message'
          element :full_name, '#case_foi_name'
          element :email, '#case_foi_email'
          element :address, '#case_foi_postal_address'

          element :type_of_requester, :xpath,
                  '//fieldset[contains(.,"Requester type")]'

          element :flag_for_disclosure_specialists, :xpath,
                  '//fieldset[contains(.,"Flag for disclosure specialists")]'

          element :dropzone_container, '.dropzone'

          # only shows up when using drop_in_dropzone
          element :uploaded_request_file_input, '#uploadedRequestFileInput'

          element :submit_button, '.button'

          def choose_type_of_requester(requester_type)
            make_radio_button_choice("case_foi_requester_type_#{requester_type}")
          end

          def choose_flag_for_disclosure_specialists(choice = 'yes')
            make_radio_button_choice("case_foi_flag_for_disclosure_specialists_#{choice}")
          end

          def choose_foi_type(choice)
            make_radio_button_choice("case_foi_type_#{choice}")
          end

          def choose_delivery_method(choice = 'sent_by_email')
            make_radio_button_choice("case_foi_delivery_method_#{choice}")
          end

          def set_received_date(received_date)
            date_received_day.set(received_date.day)
            date_received_month.set(received_date.month)
            date_received_year.set(received_date.year)
          end

          def fill_in_case_details(params={})
            type = params.delete(:type) || 'standard'
            kase = FactoryBot.build :case, params

            set_received_date(kase.received_date)

            full_name.set kase.name
            email.set kase.email
            address.set kase.postal_address
            choose_delivery_method kase.delivery_method
            subject.set kase.subject
            if kase.sent_by_email?
              full_request.set kase.message
            elsif kase.sent_by_post?
              kase.uploaded_request_files.each do |file|
                drop_in_dropzone(file)
              end
            else
              raise ArgumentError.new(
                      "unrecognised case delivery method #{kase.delivery_method}"
                    )
            end
            choose_foi_type(type)

            choose_type_of_requester(kase.requester_type)

            determine_flag_for_disclosure_specialist kase
            kase
          end

          def determine_flag_for_disclosure_specialist(kase)
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
          end

          def drop_in_dropzone(file_path)
            super file_path: file_path,
                  input_name: dropzone_container['data-file-input-name'],
                  container_selector: '#delivery-method-fields'
          end
        end
      end
    end
  end
end
