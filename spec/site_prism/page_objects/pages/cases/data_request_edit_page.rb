module PageObjects
  module Pages
    module Cases
      class DataRequestEditPage < SitePrism::Page
        set_url "/cases/{case_id}/data_request_areas/{data_request_area_id}/data_requests/{id}{/edit}"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        element :request_type, ".data-request__request_type"

        section :form, "form#edit_data_request" do
          element :date_from_day, "#data_request_date_from_dd"
          element :date_from_month, "#data_request_date_from_mm"
          element :date_from_year, "#data_request_date_from_yyyy"

          element :date_to_day, "#data_request_date_to_dd"
          element :date_to_month, "#data_request_date_to_mm"
          element :date_to_year, "#data_request_date_to_yyyy"

          element :date_received_day, "#data_request_cached_date_received_dd"
          element :date_received_month, "#data_request_cached_date_received_mm"
          element :date_received_year, "#data_request_cached_date_received_yyyy"

          element :cached_num_pages, 'input[name*="[cached_num_pages]"]'
          element :completed, 'input[name*="[completed]"]'

          def mark_complete
            selector = "input#data_request_completed"

            if Capybara.current_driver == Capybara.javascript_driver
              find(selector, visible: false).click
            else
              find(selector).set(true)
            end
          end

          def set_date_received(date_received)
            date_received_day.set(date_received.day)
            date_received_month.set(date_received.month)
            date_received_year.set(date_received.year)
          end
        end

        element :submit_button, ".button"
      end
    end
  end
end
