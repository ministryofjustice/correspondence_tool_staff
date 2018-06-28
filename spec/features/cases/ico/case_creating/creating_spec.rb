require 'rails_helper'

feature 'FOI Case creation by a manager' do

  given(:responder)       { create(:responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { create :disclosure_bmt_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  background do
    responding_team
    find_or_create :team_dacu_disclosure
    login_as manager
    cases_page.load
  end

  scenario 'creating an ICO case', js: true do
    stub_s3_uploader_for_all_files!
    request_attachment = Rails.root.join('spec', 'fixtures', 'request-1.pdf')

    new_case = create_ico_case_step(
      # original_case_type: 'foi',
      uploaded_request_files: [request_attachment]
    )

    # new_case = Case::Base.last
    # request_attachment = new_case.attachments.request.first
    # expect(request_attachment.key).to match %{/request-1.pdf$}

    # assign_case_step business_unit: responder.responding_teams.first
  end
end
