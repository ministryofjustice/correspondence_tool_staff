require 'rails_helper'

feature 'SAR Internal Review Case creation by a manager' do

  given(:responder)       { find_or_create(:sar_responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { find_or_create :disclosure_bmt_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }

  let(:sar_case) { create(:sar_case) }
  let(:foi_case) { create(:foi_case) }

  background do
    responding_team
    find_or_create :team_dacu_disclosure
    login_as manager
    cases_page.load
  end

  scenario 'creating a SAR internal review case', js: true do
    click_link 'Create case', match: :first

    expect(page).to have_content("SAR IR - Subject access request internal review")

    click_link "SAR IR - Subject access request internal review"

    expect(page).to have_content("Link case details")

    fill_in :sar_internal_review_original_case_number, with: foi_case.number

    click_button 'Continue'

    expect(page).to have_content("Original case cannot link a SAR Internal review case to a FOI as a original case")


    fill_in :sar_internal_review_original_case_number, with: sar_case.number

    click_button 'Continue'

    click_link 'Back', visible: false, match: :first

    expect(page).to have_content("Link case details")

    fill_in :sar_internal_review_original_case_number, with: sar_case.number

    click_button 'Continue'

    expect(page).to have_content(sar_case.subject_full_name)
    expect(page).to have_content(sar_case.subject)
    expect(page).to have_content(sar_case.email)
    expect(page).to have_content('Check details of the SAR')

    choose 'sar_internal_review[original_case_number]', option: 'yes', visible: false

    click_button 'Continue'

    expect(page).to have_content("Add case details")
    expect(page).to have_content("Subject type")
    expect(page).to have_content("Offender")
    expect(page).to have_content("Full name of subject")
    expect(page).to have_content("Subject 1")

    # form details
    Capybara.find(:css, '#sar_internal_review_third_party_true', visible: false).click
    fill_in :sar_internal_review_name, with: "Joe Bloggs"
    fill_in :sar_internal_review_third_party_relationship, with: "Solicitor"
    click_link 'Today'
    fill_in :sar_internal_review_message, with: "Case message"
    Capybara.find(:css, '#sar_internal_review_reply_method_send_by_post', visible: false).click
    fill_in :sar_internal_review_postal_address, with: "123, Test road, AB1 3CD"
    expect(page).to have_content("Is this information being requested on someone else's behalf?")
    expect(page).to have_content("Case summary")
    expect(page).to have_content("Full case details")
    expect(page).to have_content("Dropzone")

    click_button 'Create case'

    expect(page).to have_content("Case created successfully")
    expect(page).to have_content("new sar case subject 1")
  end
end
