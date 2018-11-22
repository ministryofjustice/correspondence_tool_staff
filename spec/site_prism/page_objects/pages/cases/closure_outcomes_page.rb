module PageObjects
  module Pages
    module Cases
      class ClosureOutcomesPage < SitePrism::Page
        # include SitePrism::Support::DropInDropzone

        set_url '/cases/{id}/process_date_responded'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        sections :case_attachments,
                 PageObjects::Sections::Cases::CaseAttachmentSection,
                 '.case-attachments-group'

        section :appeal_outcome, '.appeal-outcome-group' do
          element :upheld, 'label[for="case_foi_appeal_outcome_name_upheld"]'
          element :upheld_in_part, 'label[for="case_foi_appeal_outcome_name_upheld_in_part"]'
          element :overturned, 'label[for="case_foi_appeal_outcome_name_overturned"]'
        end

        section :ico_decision, '.ico-decision' do
          element :upheld, 'input#case_ico_ico_decision_upheld', visible: false
          element :overturned, 'input#case_ico_ico_decision_overturned', visible: false
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

        def fill_in_ico_date_responded(date)
          date_responded_day_ico.set(date.day)
          date_responded_month_ico.set(date.month)
          date_responded_year_ico.set(date.year)
        end


        def get_exemption(abbreviation:)
          exemption = CaseClosure::Exemption.find_by(abbreviation: abbreviation)
          exemptions.find("input#case_foi_exemption_ids_#{exemption.id}",
                          visible: false)
        end

        def drop_in_dropzone(file_path)
          super file_path: file_path,
                input_name: 'case_ico[uploaded_ico_decision_files][]',
                container_selector: '.dropzone:first'
        end
      end
    end
  end
end
