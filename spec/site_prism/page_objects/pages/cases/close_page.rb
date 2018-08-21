module PageObjects
  module Pages
    module Cases
      class ClosePage < SitePrism::Page
        set_url '/cases/{id}/close'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        sections :case_attachments,
                 PageObjects::Sections::Cases::CaseAttachmentSection,
                 '.case-attachments-group'

        element :date_responded_day, :case_form_element, 'date_responded_dd'
        element :date_responded_month, :case_form_element, 'date_responded_mm'
        element :date_responded_year, :case_form_element, 'date_responded_yyyy'

        section :appeal_outcome, '.appeal-outcome-group' do
          element :upheld, 'label[for="case_foi_appeal_outcome_name_upheld"]'
          element :upheld_in_part, 'label[for="case_foi_appeal_outcome_name_upheld_in_part"]'
          element :overturned, 'label[for="case_foi_appeal_outcome_name_overturned"]'
        end

        section :is_info_held, '.js-info-held-status' do
          element :held, 'input#case_foi_info_held_status_abbreviation_held', visible: false
          element :yes,  'input#case_foi_info_held_status_abbreviation_held', visible: false

          element :part_held,    'input#case_foi_info_held_status_abbreviation_part_held', visible: false
          element :held_in_part, 'input#case_foi_info_held_status_abbreviation_part_held', visible: false

          element :not_held, 'input#case_foi_info_held_status_abbreviation_not_held', visible: false
          element :no,       'input#case_foi_info_held_status_abbreviation_not_held', visible: false

          element :not_confirmed, 'input#case_foi_info_held_status_abbreviation_not_confirmed', visible: false
          element :other,         'input#case_foi_info_held_status_abbreviation_not_confirmed', visible: false
        end

        section :outcome, '.js-outcome-group' do
          element :granted,         'label[for="case_foi_outcome_abbreviation_granted"]'
          element :granted_in_full, 'label[for="case_foi_outcome_abbreviation_granted"]'

          element :part,            'label[for="case_foi_outcome_abbreviation_part"]'
          element :refused_in_part, 'label[for="case_foi_outcome_abbreviation_part"]'

          element :refused,       'label[for="case_foi_outcome_abbreviation_refused"]'
          element :refused_fully, 'label[for="case_foi_outcome_abbreviation_refused"]'
        end

        section :other_reasons, '.js-other-reasons' do
          elements :options, 'label'
          element :tmm, :xpath, '//input[@value="tmm"]//..'
          element :ncnd, :xpath, '//input[@value="ncnd"]//..'
        end

        section :exemptions, '.js-refusal-exemptions' do
          elements :exemption_options, 'label'
          element :s12_exceeded_cost, :xpath, '//input[@data-omit-for-part-refused="true"]//..'
        end

        section :missing_info, '.missing-info' do
          element :yes, 'input#case_sar_missing_info_yes', visible: false
          element :no,  'input#case_sar_missing_info_no', visible: false
        end

        section :ico,
                PageObjects::Sections::Cases::ICO::ClosureSection,
                '.case-ico'

        element :submit_button, '.button'

        def fill_in_date_responded(date)
          date_responded_day.set(date.day)
          date_responded_month.set(date.month)
          date_responded_year.set(date.year)
        end

        def get_exemption(abbreviation:)
          exemption = CaseClosure::Exemption.find_by(abbreviation: abbreviation)
          exemptions.find("input#case_foi_exemption_ids_#{exemption.id}",
                          visible: false)
        end
      end
    end
  end
end
