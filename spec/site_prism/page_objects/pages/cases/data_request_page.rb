module PageObjects
  module Pages
    module Cases
      class DataRequestPage < PageObjects::Pages::Base
        set_url "/cases/{case_id}/data_requests{/new}"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        section :form, "#new_data_request" do
          element :location, 'input[name*="[location]"]'
          element :request_type, :xpath,
                  '//fieldset[contains(.,"What data is needed?")]'

          element :request_type_note, "#data_request_request_type_note"
          element :request_type_note_for_nomis, "#data_request_request_type_note_for_nomis"

          element :date_requested_day, "#data_request_date_requested_dd"
          element :date_requested_month, "#data_request_date_requested_mm"
          element :date_requested_year, "#data_request_date_requested_yyyy"

          element :date_from_day, "#data_request_date_from_dd"
          element :date_from_month, "#data_request_date_from_mm"
          element :date_from_year, "#data_request_date_from_yyyy"

          element :date_to_day, "#data_request_date_to_dd"
          element :date_to_month, "#data_request_date_to_mm"
          element :date_to_year, "#data_request_date_to_yyyy"

          def choose_request_type(request_type)
            make_radio_button_choice("data_request_request_type_#{request_type}")
          end

          def set_date_requested(date_requested)
            date_requested_day.set(date_requested.day)
            date_requested_month.set(date_requested.month)
            date_requested_year.set(date_requested.year)
          end

          def set_date_from(date_from)
            date_from_day.set(date_from.day)
            date_from_month.set(date_from.month)
            date_from_year.set(date_from.year)
          end

          def set_date_to(date_to)
            date_to_day.set(date_to.day)
            date_to_month.set(date_to.month)
            date_to_year.set(date_to.year)
          end

          def make_radio_button_choice(choice_id)
            selector = "input##{choice_id}"

            if Capybara.current_driver == Capybara.javascript_driver
              find(selector, visible: false).click
            else
              find(selector).set(true)
            end
          end

          element :submit_button, ".button"
        end
      end
    end
  end
end
