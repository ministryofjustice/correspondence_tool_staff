module PageObjects
  module Pages
    module Cases
      class ClosePage < SitePrism::Page
        include SitePrism::Support::DropInDropzone

        set_url "/cases/{correspondence_type}/{id}/close"

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, ".global-nav"

        sections :case_attachments,
                 PageObjects::Sections::Cases::CaseAttachmentSection,
                 ".case-attachments-group"

        element :date_responded_day, :case_form_element, "date_responded_dd"
        element :date_responded_month, :case_form_element, "date_responded_mm"
        element :date_responded_year, :case_form_element, "date_responded_yyyy"

        element :date_responded_day_ico, :case_form_element, "date_ico_decision_received_dd"
        element :date_responded_month_ico, :case_form_element, "date_ico_decision_received_mm"
        element :date_responded_year_ico, :case_form_element, "date_ico_decision_received_yyyy"

        element :uploaded_request_file_input, "#uploadedRequestFileInput"

        section :appeal_outcome, ".appeal-outcome-group" do
          element :upheld, 'label[for="foi_appeal_outcome_name_upheld"]'
          element :upheld_in_part, 'label[for="foi_appeal_outcome_name_upheld_in_part"]'
          element :overturned, 'label[for="foi_appeal_outcome_name_overturned"]'
        end

        section :ico_decision, ".ico-decision" do
          element :upheld, "input#ico_ico_decision_upheld", visible: false
          element :overturned, "input#ico_ico_decision_overturned", visible: false
        end

        section :is_info_held, ".js-info-held-status" do
          element :held, "input#foi_info_held_status_abbreviation_held", visible: false
          element :yes,  "input#foi_info_held_status_abbreviation_held", visible: false

          element :part_held,    "input#foi_info_held_status_abbreviation_part_held", visible: false
          element :held_in_part, "input#foi_info_held_status_abbreviation_part_held", visible: false

          element :not_held, "input#foi_info_held_status_abbreviation_not_held", visible: false
          element :no,       "input#foi_info_held_status_abbreviation_not_held", visible: false

          element :not_confirmed, "input#foi_info_held_status_abbreviation_not_confirmed", visible: false
          element :other,         "input#foi_info_held_status_abbreviation_not_confirmed", visible: false
        end

        section :outcome, ".js-outcome-group" do
          element :granted,         'label[for="foi_outcome_abbreviation_granted"]'
          element :granted_in_full, 'label[for="foi_outcome_abbreviation_granted"]'

          element :part,            'label[for="foi_outcome_abbreviation_part"]'
          element :refused_in_part, 'label[for="foi_outcome_abbreviation_part"]'

          element :refused,       'label[for="foi_outcome_abbreviation_refused"]'
          element :refused_fully, 'label[for="foi_outcome_abbreviation_refused"]'
        end

        section :other_reasons, ".js-other-reasons" do
          elements :options, "label"
          element :tmm, :xpath, '//input[@value="tmm"]//..'
          element :ncnd, :xpath, '//input[@value="ncnd"]//..'
        end

        section :exemptions, ".js-refusal-exemptions" do
          elements :exemption_options, "label"
          element :s12_exceeded_cost, :xpath, '//input[@data-omit-for-part-refused="true"]//..'
        end

        section :missing_info, ".missing-info" do
          element :yes, "input#sar_missing_info_yes", visible: false
          element :no,  "input#sar_missing_info_no", visible: false
        end

        section :ico,
                PageObjects::Sections::Cases::ICO::ClosureSection,
                ".case-ico"

        element :submit_button, ".button"
        element :cancel, "a.acts-like-button.button-left-spacing"

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
          exemption = CaseClosure::Exemption.find_by(abbreviation:)
          exemptions.find("input#foi_exemption_ids_#{exemption.id}",
                          visible: false)
        end

        def get_late_team(team_id)
          find("#foi_late_team_id_#{team_id}", visible: false)
        end

        def drop_in_dropzone(file_path)
          super file_path:,
                input_name: "ico[uploaded_ico_decision_files][]",
                container_selector: ".dropzone:first"
        end
      end
    end
  end
end
