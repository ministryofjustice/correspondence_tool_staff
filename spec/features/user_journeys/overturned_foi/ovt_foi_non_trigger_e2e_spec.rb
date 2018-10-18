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
    kase = create_and_assign_overturned_ico user: manager,
                                            responding_team: responding_team,
                                            ico_case: original_appeal_case,
                                            flag_for_disclosure: false,
                                            do_logout: false

    add_message_to_case kase: kase,
                        message: 'Case created'

    accept_case kase: kase,
                user: responder

    set_case_dates_back_by(kase, 7.business_days)

    extend_for_pit kase: kase,
                   user: manager,
                   new_deadline: 20.business_days.from_now

    upload_response kase: kase,
                    user: responder,
                    file: UPLOAD_RESPONSE_DOCX_FIXTURE

    mark_case_as_sent kase: kase,
                      user: responder

    close_case kase: kase,
               user: manager
  end
end
