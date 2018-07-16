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
    related_timeliness_review = create :closed_timeliness_review

    request_attachment = Rails.root.join('spec', 'fixtures', 'request-1.pdf')

    new_case = create_ico_case_step(
      original_case: original_foi,
      related_cases: [related_timeliness_review],
      uploaded_request_files: [request_attachment]
    )

    request_attachment = new_case.attachments.request.first
    expect(request_attachment.key).to match %{/request-1.pdf$}

    expect(new_case.original_case).to eq original_foi

    expect(new_case.related_cases).to eq [related_timeliness_review]

    assign_case_step business_unit: responder.responding_teams.first
  end
end
