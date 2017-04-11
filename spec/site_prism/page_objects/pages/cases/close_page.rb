module PageObjects
  module Pages
    module Cases
      class ClosePage < SitePrism::Page
        set_url '/cases/{id}'

        sections :responses,
                 PageObjects::Sections::ResponseAttachmentSection,
                 '#request--responses tr'

        element :date_responded_day, '#case_date_responded_dd'
        element :date_responded_month, '#case_date_responded_mm'
        element :date_responded_year, '#case_date_responded_yyyy'

        element :outcome_radio_button_fully_granted,
                'label[for="case_outcome_name_granted_in_full"]'

        element :outcome_radio_button_refused_fully,
                'label[for="case_outcome_name_refused_fully"]'

        section :refusal, '#refusal' do
          element :info_not_held,
                  'label[for="case_refusal_reason_name_information_not_held"]'
          element :exemption_applied,
                  'label[for="case_refusal_reason_name_exemption_applied"]'
          section :exemptions, '#refusal_exemptions' do
            elements :exemption_options, 'label'

            element :ncnd, 'label[for="case_exemption_ids_10"]'

            element :court_records, 'label[for="case_exemption_ids_13"]'

          end
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
