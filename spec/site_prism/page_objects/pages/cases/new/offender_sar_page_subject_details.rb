module PageObjects
  module Pages
    module Cases
      module New
        class OffenderSARPageSubjectDetails < PageObjects::Pages::Base
          set_url "/cases/offender_sars/new"

          section :primary_navigation,
                  PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

          section :page_heading,
                  PageObjects::Sections::PageHeadingSection, ".page-heading"

          element :subject_full_name, "#offender_sar_subject_full_name"
          element :prison_number, "#offender_sar_prison_number"
          element :subject_aliases, "#offender_sar_subject_aliases"
          element :previous_case_numbers, "#offender_sar_previous_case_numbers"
          element :other_subject_ids, "#offender_sar_other_subject_ids"
          element :case_reference_number, "#offender_sar_case_reference_number"
          element :probation_area, "#offender_sar_probation_area"
          element :date_of_birth_dd, "#offender_sar_date_of_birth_dd"
          element :date_of_birth_mm, "#offender_sar_date_of_birth_mm"
          element :subject_address, "#offender_sar_subject_address"
          element :date_of_birth_yyyy, "#offender_sar_date_of_birth_yyyy"
          element :find_an_address_button, "#open-button"
          element :submit_button, "[value=Continue]"

          def fill_in_case_details(params = {})
            kase = FactoryBot.build_stubbed :offender_sar_case, params
            if params.present? && params[:subject_full_name].present?
              subject_full_name.set(params[:subject_full_name])
            else
              subject_full_name.set("Sabrina Adams")
            end
            prison_number.set kase.prison_number
            probation_area.set kase.probation_area
            subject_address.set kase.subject_address
            subject_aliases.set kase.subject_aliases
            previous_case_numbers.set kase.previous_case_numbers
            set_date_of_birth kase.date_of_birth
            other_subject_ids.set kase.other_subject_ids
            case_reference_number.set kase.case_reference_number

            choose("offender_sar_subject_type_offender", visible: false)
            choose("offender_sar_flag_as_high_profile_false", visible: false)
            if params.present? && params["rejected"] == "true"
              # maybe target with something else on the page
              choose("offender_sar_flag_as_dps_missing_data_false", visible: false)
            end
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
