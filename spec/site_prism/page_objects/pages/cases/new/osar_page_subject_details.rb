module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARPageSubjectDetails < PageObjects::Pages::Base

          set_url '/cases/new/offender'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :subject_full_name, '#case_sar_subject_full_name'

          element :submit_button, '.button'

          def fill_in_case_details(_params={})
            fill_in :offender_sar_case_form_subject_full_name, with: "Bob Smith"
            fill_in :offender_sar_case_form_prison_number, with: "ABC123"
            fill_in :offender_sar_case_form_subject_aliases, with: "Bobby"
            fill_in :offender_sar_case_form_previous_case_numbers, with: "12345"
            fill_in :offender_sar_case_form_other_subject_ids, with: "1,2,3"
            fill_in :offender_sar_case_form_date_of_birth_dd, with: "10"
            fill_in :offender_sar_case_form_date_of_birth_mm, with: "10"
            fill_in :offender_sar_case_form_date_of_birth_yyyy, with: "2000"
            choose('offender_sar_case_form_subject_type_offender', visible: false)
            choose('offender_sar_case_form_flag_for_disclosure_specialists_no', visible: false)
          end

          # def set_received_date(received_date)
          #   date_received_day.set(received_date.day)
          #   date_received_month.set(received_date.month)
          #   date_received_year.set(received_date.year)
          # end
        end
      end
    end
  end
end
