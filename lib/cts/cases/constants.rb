module CTS
  module Cases
    class Constants


      CASE_TYPES = %w{
          Case::FOI::Standard
          Case::FOI::ComplianceReview
          Case::FOI::TimelinessReview
          Case::SAR
      }


      CASE_JOURNEYS = {
          unflagged: [
              :awaiting_responder,
              :drafting,
              :awaiting_dispatch,
              :responded,
              :closed,
          ],
          flagged_for_dacu_disclosure: [
              :awaiting_responder,
              :accepted_by_dacu_disclosure,
              :drafting,
              :pending_dacu_disclosure_clearance,
              :awaiting_dispatch,
              :responded,
              :closed,
          ],
          flagged_for_press_office: [
              :awaiting_responder,
              :taken_on_by_press_office,
              :accepted_by_dacu_disclosure,
              :drafting,
              :pending_dacu_disclosure_clearance,
              :pending_press_office_clearance,
          ],
          flagged_for_private_office: [
              :awaiting_responder,
              :taken_on_by_private_office,
              :accepted_by_dacu_disclosure,
              :drafting,
              :pending_dacu_disclosure_clearance,
              :pending_press_office_clearance,
              :pending_private_office_clearance,
          ]
      }

    end
  end
end
