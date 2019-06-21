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

          element :subject_full_name, '#offender_sar_case_form_subject_full_name'

          element :prison_number, '#offender_sar_case_form_prison_number'

          element :subject_aliases, '#offender_sar_case_form_subject_aliases'

          element :previous_case_numbers, '#offender_sar_case_form_previous_case_numbers'

          element :other_subject_ids, '#offender_sar_case_form_other_subject_ids'

          element :date_of_birth_dd, '#offender_sar_case_form_date_of_birth_dd'

          element :date_of_birth_mm, '#offender_sar_case_form_date_of_birth_mm'

          element :date_of_birth_yyyy, '#offender_sar_case_form_date_of_birth_yyyy'

          element :subject_type, '#offender_sar_case_form_subject_type_offender'

          element :submit_button, '.button'

          def fill_in_case_details(params={})
            kase = FactoryBot.build :offender_sar_case, params

            subject_full_name.set kase.subject_full_name
            prison_number.set kase.prison_number
            subject_aliases.set kase.subject_aliases
            previous_case_numbers.set kase.previous_case_numbers
            set_date_of_birth kase.date_of_birth
            choose_subject_type kase.subject_type
            choose_flag_for_disclosure_specialists "no"


            #fill_in :offender_sar_case_form_prison_number, with: "ABC123"
            #fill_in :offender_sar_case_form_subject_aliases, with: "Bobby"
            #fill_in :offender_sar_case_form_previous_case_numbers, with: "12345"
            #ill_in :offender_sar_case_form_other_subject_ids, with: "1,2,3"
            #ill_in :offender_sar_case_form_date_of_birth_dd, with: "10"
            #ill_in :offender_sar_case_form_date_of_birth_mm, with: "10"
            #ill_in :offender_sar_case_form_date_of_birth_yyyy, with: "2000"
            #choose('offender_sar_case_form_subject_type_offender', visible: false)
            #choose('offender_sar_case_form_flag_for_disclosure_specialists_no', visible: false)
          end

          def set_date_of_birth(date_of_birth)
            date_of_birth_dd.set(date_of_birth.day)
            date_of_birth_mm.set(date_of_birth.month)
            date_of_birth_yyyy.set(date_of_birth.year)
          end

          def choose_flag_for_disclosure_specialists(choice = 'yes')
            make_radio_button_choice("#offender_sar_case_form_flag_for_disclosure_specialists_#{choice}")
          end
        end
      end
    end
  end
end
