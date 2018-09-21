require 'rails_helper'

feature 'ICO Overturned FOI case' do
  include CaseDateManipulation
  include Features::Interactions
  given(:responder)            { create :responder }
  given(:responding_team)      { responder.responding_teams.first }
  given(:manager)              { create :disclosure_bmt_user }
  given!(:overturned_foi_type) { create :overturned_foi_correspondence_type }
  given(:original_appeal_case) { create :closed_ico_foi_case, :overturned_by_ico,
                                        responding_team: responding_team }

  scenario 'end-to-end journey', js: true do
    login_step user: manager

    kase = create_overturned_foi_case_step(
      ico_case: original_appeal_case,
    )
    # expect(assignments_new_page).to be_displayed

    # kase = create_and_assign_overturned_foi user: manager,
    #                                         responding_team: responding_team,
    #                                         ico_case: original_appeal_case

    # add_message_to_case kase: kase,
    #                     message: 'This. Is. A. Test.',
    #                     do_logout: true

    # accept_case kase: kase,
    #             user: responder,
    #             do_logout: false

    # add_message_to_case kase: kase,
    #                     message: 'This. Is. A. Test.',
    #                     do_logout: true

    # close_foi_case user: responder,
    #                kase: kase,
    #                timeliness: 'in time'
  end
end
