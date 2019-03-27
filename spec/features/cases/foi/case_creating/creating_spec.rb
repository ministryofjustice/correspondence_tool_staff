require 'rails_helper'

feature 'FOI Case creation by a manager' do

  given!(:responder)       { find_or_create(:foi_responder) }
  given!(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { find_or_create :disclosure_bmt_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  background do
    find_or_create :team_dacu_disclosure
    login_as manager
    cases_page.load
  end

  scenario 'creating a case that does not need clearance', js: true do
    kase = create_foi_case_step flag_for_disclosure: false
    expect(assignments_new_page).to be_displayed(case_id: kase.id)

    assign_case_step business_unit: responder.responding_teams.first
  end

  scenario 'creating a case that needs clearance' do
    create_foi_case_step flag_for_disclosure: true

    new_case = Case::Base.last
    expect(new_case.requires_clearance?).to be true
  end

  scenario 'creating a case with request attachments', js: true  do
    request_attachment = Rails.root.join('spec', 'fixtures', 'request-1.pdf')

    create_foi_case_step delivery_method: :sent_by_post,
                         uploaded_request_files: [request_attachment]

    new_case = Case::Base.last
    request_attachment = new_case.attachments.request.first
    expect(request_attachment.key).to match %{/request-1.pdf$}
  end
end
