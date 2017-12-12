require 'rails_helper'

feature 'FOI Case creation by a manager' do

  given(:responder)       { create(:responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { create :disclosure_bmt_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  background do
    responding_team
    find_or_create :team_dacu_disclosure
    create(:category, :foi)
    login_as manager
    cases_page.load
  end

  scenario 'creating a case that does not need clearance', js: true do
    create_case_step flag_for_disclosure: false

    assign_case_step business_unit: responder.responding_teams.first
  end

  scenario 'creating a case that needs clearance' do
    create_case_step flag_for_disclosure: true

    new_case = Case.last
    expect(new_case.requires_clearance?).to be true
  end

  scenario 'creating a case with request attachments', js: true do
    stub_s3_uploader_for_all_files!
    request_attachment = Rails.root.join('spec', 'fixtures', 'request-1.pdf')

    create_case_step delivery_method: :sent_by_post,
                     uploaded_request_files: [request_attachment]

    new_case = Case.last
    request_attachment = new_case.attachments.request.first
    expect(request_attachment.key).to match %{/request-1.pdf$}
  end
end
