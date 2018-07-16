require 'rails_helper'

feature 'ICO case creation' do

  given(:responder)                 { create(:responder) }
  given(:responding_team)           { create :responding_team, responders: [responder] }
  given(:manager)                   { create :disclosure_bmt_user }
  given(:managing_team)             { create :managing_team, managers: [manager] }
  given(:original_foi)              { create :closed_case }
  given(:related_timeliness_review) { create :closed_timeliness_review }

  background do
    responding_team
    find_or_create :team_dacu_disclosure
    original_foi
    related_timeliness_review
    login_as manager
    cases_page.load
  end

  scenario 'creating an ICO appeal for an FOI case', js: true do

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

  context 'creating an ICO appeal' do
    scenario ' - linking Original case', js: true do

      request_attachment = Rails.root.join('spec', 'fixtures', 'request-1.pdf')

      cases_new_ico_page.load

      cases_new_ico_page.original_case_number.set ''

      cases_new_ico_page.link_original_case.click

      expect(cases_new_ico_page.original_case_number_error.text).to eq 'Original case not found'

      cases_new_ico_page.original_case_number.set 'abcd13'

      cases_new_ico_page.link_original_case.click

      expect(cases_new_ico_page.original_case_number_error.text).to eq 'Original case not found'

      cases_new_ico_page.original_case_number.set original_foi.number

      cases_new_ico_page.link_original_case.click

      cases_new_ico_page.wait_until_original_case_number_error_invisible

      expect(cases_new_ico_page).to have_no_original_case_number_error

      cases_new_ico_page.wait_until_related_case_number_visible
    end

    scenario ' - linking relate case', js: true do

      request_attachment = Rails.root.join('spec', 'fixtures', 'request-1.pdf')

      cases_new_ico_page.load

      cases_new_ico_page.original_case_number.set original_foi.number

      cases_new_ico_page.link_original_case.click

      cases_new_ico_page.wait_until_related_case_number_visible

      cases_new_ico_page.related_case_number.set ''

      cases_new_ico_page.link_related_case.click

      expect(cases_new_ico_page.related_case_number_error.text).to eq 'Related case not found'

      cases_new_ico_page.related_case_number.set 'abcd13'

      cases_new_ico_page.link_related_case.click

      expect(cases_new_ico_page.related_case_number_error.text).to eq 'Related case not found'

      cases_new_ico_page.related_case_number.set original_foi.number

      cases_new_ico_page.link_related_case.click

      cases_new_ico_page.wait_until_related_case_number_visible
    end
  end
end
