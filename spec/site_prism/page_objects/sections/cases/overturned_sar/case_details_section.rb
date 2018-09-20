module PageObjects
  module Sections
    module Cases
      module OverturnedSAR
        class CaseDetailsSection < SitePrism::Section

          element :section_heading, '.case-details .request--heading'

          section :case_type, 'tr.case-type' do
            element :trigger, 'td .ico-trigger'
            element :type, 'td'
          end
          element :ico_case_number, 'tr.ico-reference td'
          element :ico_officer_name, 'tr.ico-officer-name td'
          element :date_received, 'tr.date-received td'
          element :draft_deadline, 'tr.case-internal-deadline td'
          element :final_deadline, 'tr.case-external-deadline td'

          element :date_responded, '.date-responded td'
          element :timeliness, '.timeliness td'
          element :time_taken, '.time-taken td'

          element :edit_case, :xpath, '//a[contains(.,"Edit case details")]'
          element :edit_case_link, :xpath, '//a[contains(.,"Edit case details")]'
          element :edit_closure, :xpath, '//a[contains(.,"Edit closure details")]'
          element :view_original_case_link, :xpath, '//a[contains(.,"See full original case details ")]'
        end
      end
    end
  end
end
