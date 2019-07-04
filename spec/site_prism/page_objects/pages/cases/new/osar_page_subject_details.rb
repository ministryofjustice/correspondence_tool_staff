module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARPageSubjectDetails < PageObjects::Pages::Base

          set_url '/cases/offender_sars/new'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :subject_full_name, '#offender_sar_subject_full_name'

          element :submit_button, '.button'

          def fill_in_case_details(_params={})
            fill_in :offender_sar_subject_full_name, with: "Bob Smith"
            fill_in :offender_sar_prison_number, with: "ABC123"
            fill_in :offender_sar_subject_aliases, with: "Bobby"
            fill_in :offender_sar_previous_case_numbers, with: "12345"
            fill_in :offender_sar_other_subject_ids, with: "1,2,3"
            fill_in :offender_sar_date_of_birth_dd, with: "10"
            fill_in :offender_sar_date_of_birth_mm, with: "10"
            fill_in :offender_sar_date_of_birth_yyyy, with: "2000"
            choose('offender_sar_subject_type_offender_sar', visible: false)
            choose('offender_sar_flag_for_disclosure_specialists_no', visible: false)
          end
        end
      end
    end
  end
end
