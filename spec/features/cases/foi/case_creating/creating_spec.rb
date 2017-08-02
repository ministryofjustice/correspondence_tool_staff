require 'rails_helper'

feature 'Case creation by a manager' do

  given(:responder)       { create(:responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { create(:manager)  }
  given(:managing_team)   { create :managing_team, managers: [manager] }


  background do
    responding_team
    find_or_create :team_dacu_disclosure
    create(:category, :foi)
    login_as manager
    cases_page.load
    cases_page.new_case_button.click
  end

  scenario 'creating a case that does not need clearance', js: true do
    expect(cases_new_page).to be_displayed

    cases_new_page.fill_in_case_details

    cases_new_page.choose_flag_for_disclosure_specialists 'no'

    click_button 'Next - Assign case'

    expect(assignments_new_page).to be_displayed

    # Browse Business Group
    assignments_new_page.choose_business_group(responder.responding_teams.first
                                                   .business_group)

    # Select Business Unit
    assignments_new_page.choose_business_unit(responder.responding_teams.first)

    expect(cases_show_page).to be_displayed

    expect(cases_show_page.text).to have_content('Case successfully created')

  end

  scenario 'creating a case that needs clearance' do
    expect(cases_new_page).to be_displayed

    cases_new_page.fill_in_case_details

    cases_new_page.choose_flag_for_disclosure_specialists 'yes'

    click_button 'Next - Assign case'

    new_case = Case.last
    expect(new_case.requires_clearance?).to be true
  end

  scenario 'creating a case with request attachments', js: true do
    stub_s3_uploader_for_all_files!
    request_attachment = Rails.root.join('spec', 'fixtures', 'request-1.pdf')

    expect(cases_new_page).to be_displayed

    cases_new_page.fill_in_case_details(
      delivery_method: :sent_by_post,
      uploaded_request_files: [request_attachment]
    )
    click_button 'Next - Assign case'

    new_case = Case.last
    request_attachment = new_case.attachments.request.first
    expect(request_attachment.key).to match %{/request-1.pdf$}
  end
end
