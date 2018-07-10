require 'rails_helper'

feature 'ICO case creation' do

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

  scenario 'creating an ICO appeal for an FOI case', js: true do
    original_foi = create :closed_case
    request_attachment = Rails.root.join('spec', 'fixtures', 'request-1.pdf')

    new_case = create_ico_case_step(
      original_case: original_foi,
      uploaded_request_files: [request_attachment]
    )

    # new_case = Case::Base.last
    request_attachment = new_case.attachments.request.first
    expect(request_attachment.key).to match %{/request-1.pdf$}

    expect(new_case.linked_cases).to include original_foi

    assign_case_step business_unit: responder.responding_teams.first
  end
end
