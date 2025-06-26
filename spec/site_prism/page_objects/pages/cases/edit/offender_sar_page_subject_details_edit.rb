module PageObjects
  module Pages
    module Cases
      module Edit
        class OffenderSARPageSubjectDetails < PageObjects::Pages::Base
          set_url "/cases/offender_sars/{id}/edit/subject_details"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :subject_full_name, "#offender_sar_subject_full_name"
          element :prison_number, "#offender_sar_prison_number"
          element :subject_aliases, "#offender_sar_subject_aliases"
          element :previous_case_numbers, "#offender_sar_previous_case_numbers"
          element :other_subject_ids, "#offender_sar_other_subject_ids"
          element :probation_area, "#offender_sar_probation_area"
          element :date_of_birth_dd, "#offender_sar_date_of_birth_dd"
          element :date_of_birth_mm, "#offender_sar_date_of_birth_mm"
          element :date_of_birth_yyyy, "#offender_sar_date_of_birth_yyyy"

          element :submit_button, "[value=Continue]"

          def edit_name(value)
            subject_full_name.set value
          end
        end
      end
    end
  end
end
