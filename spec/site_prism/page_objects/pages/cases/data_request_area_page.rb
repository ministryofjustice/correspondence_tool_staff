module PageObjects
  module Pages
    module Cases
      class DataRequestAreaPage < PageObjects::Pages::Base
        set_url "/cases/{case_id}/data_request_areas{/new}"

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, ".page-heading"

        section :form, "#new_data_request_area" do
          element :data_request_area_type, :xpath,
                  '//fieldset[contains(.,"Where is the data you are requesting from?")]'

          def choose_area_request_type(request_type)
            make_radio_button_choice("data_request_area_data_request_area_type_#{request_type}")
          end

          element :submit_button, ".button"
        end
      end
    end
  end
end
