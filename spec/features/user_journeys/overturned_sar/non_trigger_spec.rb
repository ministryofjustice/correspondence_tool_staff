require 'rails_helper'

feature 'SAR overturned case' do
  include CaseDateManipulation
  include Features::Interactions
  given(:responder)                           { create :responder }
  given(:responding_team)                     { responder.responding_teams.first }
  given(:manager)                             { create :disclosure_bmt_user }
  given!(:overturned_sar_correspondence_type) { create :overturned_sar_correspondence_type }
  given(:original_appeal_case)                { create :closed_ico_sar_case, :overturned_by_ico,
                                                        responding_team: responding_team }

  scenario 'end-to-end journey', js: true do
    kase = create_and_assign_overturned_sar user: manager,
                                            responding_team: responding_team,
                                            ico_case: original_appeal_case

    add_message_to_case kase: kase,
                        message: 'This. Is. A. Test.',
                        do_logout: true

    accept_case kase: kase,
                user: responder,
                do_logout: false

    add_message_to_case kase: kase,
                        message: 'This. Is. A. Test.',
                        do_logout: true

    close_sar_case user: responder,
                   kase: kase,
                   timeliness: 'in time'
  end
end
