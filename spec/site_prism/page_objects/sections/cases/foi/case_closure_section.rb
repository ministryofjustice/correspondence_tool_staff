module PageObjects
  module Sections
    module Cases
      module FOI
        class CaseClosureSection < SitePrism::Section
          sections :case_attachments,
                   PageObjects::Sections::Cases::CaseAttachmentSection,
                   ".case-attachments-group"

          element :date_responded_day, :case_form_element, "date_responded_dd"
          element :date_responded_month, :case_form_element, "date_responded_mm"
          element :date_responded_year, :case_form_element, "date_responded_yyyy"

          section :appeal_outcome, ".appeal-outcome-group" do
            element :upheld, 'label[for="foi_appeal_outcome_name_upheld"]'
            element :upheld_in_part, 'label[for="foi_appeal_outcome_name_upheld_in_part"]'
            element :overturned, 'label[for="foi_appeal_outcome_name_overturned"]'
          end

          section :is_info_held, ".js-info-held-status" do
            element :yes, :xpath, '//input[@value="held"]//..'
            element :held_in_part, :xpath, '//input[@value="part_held"]//..'
            element :no, :xpath, '//input[@value="not_held"]//..'
            element :other, :xpath, '//input[@value="not_confirmed"]//..'
          end

          section :outcome, ".js-outcome-group" do
            element :granted_in_full, 'label[for="foi_outcome_name_granted_in_full"]'
            element :refused_in_part, 'label[for="foi_outcome_name_refused_in_part"]'
            element :refused_fully, 'label[for="foi_outcome_name_refused_fully"]'
          end

          section :other_reasons, ".js-other-reasons" do
            elements :options, "label"
            element :ncnd, :xpath, '//input[@value="Neither confirm nor deny (NCND)"]//..'
          end

          section :exemptions, ".js-refusal-exemptions" do
            elements :exemption_options, "label"
            element :s12_exceeded_cost, :xpath, '//input[@data-omit-for-part-refused="true"]//..'
          end
        end
      end
    end
  end
end
