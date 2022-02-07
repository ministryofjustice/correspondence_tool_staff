require 'page_objects/pages/cases/close_page'

module PageObjects
  module Pages
    module Cases
      class EditClosurePage < ClosePage
        set_url '/cases/{correspondence_type}/{id}/edit_closure'

        section :sar_ir_outcome, '.appeal-outcome-group' do
          element :upheld, 'label[for="sar_internal_review_sar_ir_outcome_upheld"]'
          element :upheld_in_part, 'label[for="sar_internal_review_sar_ir_outcome_upheld_in_part"]'
          element :overturned, 'label[for="sar_internal_review_sar_ir_outcome_overturned"]'
        end

        section :sar_ir_responsible_for_outcome, '.responsible-for-outcome-group' do
          element :disclosure, 'input[id^="sar_internal_review_team_responsible_for_outcome_id_"]', match: :first, visible: false
        end

        section :sar_ir_outcome_reasons, '.outcome-reasons-group' do
        end
      end
    end
  end
end

