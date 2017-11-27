module PageObjects
  module Pages
    module Cases
      class ClosePage < SitePrism::Page
        set_url '/cases/{id}/close'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        sections :case_attachments,
                 PageObjects::Sections::Cases::CaseAttachmentSection,
                 '.case-attachments-group'

        element :date_responded_day, '#case_date_responded_dd'
        element :date_responded_month, '#case_date_responded_mm'
        element :date_responded_year, '#case_date_responded_yyyy'

        section :appeal_outcome, '.appeal-outcome-group' do
          element :upheld, 'label[for="case_appeal_outcome_name_upheld"]'
          element :upheld_in_part, 'label[for="case_appeal_outcome_name_upheld_in_part"]'
          element :reversed, 'label[for="case_appeal_outcome_name_reversed"]'
        end

        section :is_info_held, '.js-info-held-status' do
          element :yes, :xpath, '//input[@value="held"]//..'
          element :held_in_part, :xpath, '//input[@value=part_held"]//..'
          element :no, :xpath, '//input[@value="not_held"]//..'
          element :other, :xpath, '//input[@value="not_confirmed"]//..'
        end

        section :outcome, '.js-outcome-group' do
          element :granted_in_full, 'label[for="case_outcome_name_granted_in_full"]'
          element :refused_in_part, 'label[for="case_outcome_name_refused_in_part"]'
          element :refused_fully, 'label[for="case_outcome_name_refused_fully"]'
        end

        section :other_reasons, '.js-other-reasons' do
          elements :options, 'label'
          element :ncnd, :xpath, '//input[@value="Neither confirm nor deny (NCND)"]//..'
        end

        section :exemptions, '.js-refusal-exemptions' do
          elements :exemption_options, 'label'
          element :s12_exceeded_cost, :xpath, '//input[@data-omit-for-part-refused="true"]//..'
        end

        element :submit_button, '.button'

        def fill_in_date_responded(date)
          date_responded_day.set(date.day)
          date_responded_month.set(date.month)
          date_responded_year.set(date.year)
        end

      end
    end
  end
end
