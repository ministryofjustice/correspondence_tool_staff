require "rails_helper"

feature "ICO Overturned FOI case" do
  include CaseDateManipulation
  include Features::Interactions
  given(:responder)            { original_appeal_case.responder }
  given(:responding_team)      { original_appeal_case.responding_team }
  given(:manager)              { find_or_create :disclosure_bmt_user }
  given!(:overturned_foi_type) { create :overturned_foi_correspondence_type }
  given(:original_appeal_case) { create :closed_ico_foi_case, :overturned_by_ico }

  scenario "end-to-end journey", js: true do
    kase = create_and_assign_overturned_ico user: manager,
                                            responding_team:,
                                            ico_case: original_appeal_case,
                                            flag_for_disclosure: false,
                                            do_logout: false

    add_message_to_case kase:,
                        message: "Case created"

    accept_case kase:,
                user: responder

    set_case_dates_back_by(kase, 7.business_days)

    extend_for_pit kase:,
                   user: manager,
                   new_deadline: 20.working.days.from_now

    upload_response kase:,
                    user: responder,
                    file: UPLOAD_RESPONSE_DOCX_FIXTURE

    mark_case_as_sent kase:,
                      user: responder

    close_case kase:,
               user: manager
  end
end
