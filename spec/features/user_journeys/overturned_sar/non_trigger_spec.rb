require "rails_helper"

feature "SAR overturned case" do
  include CaseDateManipulation
  include Features::Interactions
  given(:responder)                           { original_appeal_case.responder }
  given(:responding_team)                     { original_appeal_case.responding_team }
  given(:manager)                             { find_or_create :disclosure_bmt_user }
  given!(:overturned_sar_correspondence_type) { create :overturned_sar_correspondence_type }
  given(:original_appeal_case)                { create :closed_ico_sar_case, :overturned_by_ico }

  scenario "end-to-end journey", js: true do
    kase = create_and_assign_overturned_ico user: manager,
                                            responding_team:,
                                            ico_case: original_appeal_case,
                                            flag_for_disclosure: false,
                                            do_logout: false

    add_message_to_case kase:,
                        message: "Case created",
                        do_logout: true

    accept_case kase:,
                user: responder,
                do_logout: false

    add_message_to_case kase:,
                        message: "Case accepted",
                        do_logout: true

    close_sar_case user: responder,
                   kase:,
                   timeliness: "in time"
  end
end
