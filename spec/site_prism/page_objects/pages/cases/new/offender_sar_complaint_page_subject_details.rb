module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARComplaintPageSubjectDetails < PageObjects::Pages::Base

          set_url '/cases/offender_sar_complaints/new'

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, '.page-heading'

          element :subject_full_name, '#offender_sar_complaint_subject_full_name'

          element :prison_number, '#offender_sar_complaint_prison_number'

          element :subject_aliases, '#offender_sar_complaint_subject_aliases'

          element :previous_case_numbers, '#offender_sar_complaint_previous_case_numbers'

          element :other_subject_ids, '#offender_sar_complaint_other_subject_ids'

          element :case_reference_number, '#offender_sar_complaint_case_reference_number'

          element :date_of_birth_dd, '#offender_sar_complaint_date_of_birth_dd'

          element :date_of_birth_mm, '#offender_sar_complaint_date_of_birth_mm'

          element :subject_address, '#offender_sar_complaint_subject_address'

          element :date_of_birth_yyyy, '#offender_sar_complaint_date_of_birth_yyyy'

          element :submit_button, '.button'

          def fill_in_case_details(params={})
            kase = FactoryBot.build :offender_sar_case, params

            subject_full_name.set 'Sabrina Adams'
            prison_number.set kase.prison_number
            subject_address.set kase.subject_address
            subject_aliases.set kase.subject_aliases
            previous_case_numbers.set kase.previous_case_numbers
            set_date_of_birth kase.date_of_birth
            other_subject_ids.set kase.other_subject_ids
            case_reference_number.set kase.case_reference_number

            choose('offender_sar_complaint_subject_type_offender', visible: false)
            choose('offender_sar_complaint_flag_as_high_profile_false', visible: false)
          end

          def set_date_of_birth(date_of_birth)
            date_of_birth_dd.set(date_of_birth.day)
            date_of_birth_mm.set(date_of_birth.month)
            date_of_birth_yyyy.set(date_of_birth.year)
          end
        end
      end
    end
  end
end
