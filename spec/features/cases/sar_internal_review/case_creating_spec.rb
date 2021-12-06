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

  def when_i_start_sar_ir_case_journey
    click_link 'Create case', match: :first

    expect(page).to have_content("SAR IR - Subject access request internal review")

    click_link "SAR IR - Subject access request internal review"
  end

  def and_i_try_to_link_an_foi_case
    expect(case_new_sar_ir_link_case_page).to have_content("Link case details")

    case_new_sar_ir_link_case_page.fill_in_original_case_number(foi_case.number)
    case_new_sar_ir_link_case_page.submit_button.click
  end

  def then_i_shoul_expect_to_see_an_error
    expect(case_new_sar_ir_link_case_page).to have_content("Original case cannot link a SAR Internal review case to a FOI as a original case")
  end

  def when_i_try_to_link_a_regular_sar_case 
    case_new_sar_ir_link_case_page.fill_in_original_case_number(sar_case.number)
    case_new_sar_ir_link_case_page.submit_button.click
  end

  def and_test_the_back_link_works
    case_new_sar_ir_confirm_sar_page.back_link.click
    expect(case_new_sar_ir_link_case_page).to have_content("Link case details")
  end

  def and_link_a_sar_case
    when_i_try_to_link_a_regular_sar_case
  end

  def then_i_should_see_the_linked_sar_case_details_on_the_confirm_page 
    expect(case_new_sar_ir_confirm_sar_page).to have_content(sar_case.subject_full_name)
    expect(case_new_sar_ir_confirm_sar_page).to have_content(sar_case.subject)
    expect(case_new_sar_ir_confirm_sar_page).to have_content(sar_case.email)
    expect(case_new_sar_ir_confirm_sar_page).to have_content('Check details of the SAR')
  end

  def when_i_confirm_the_linked_sar_details
    case_new_sar_ir_confirm_sar_page.original_case_number.click
    case_new_sar_ir_confirm_sar_page.submit_button.click
  end

  def then_i_should_see_the_correct_details_pre_populated_on_the_sar_ir_form
    expect(page).to have_content("Add case details")
    expect(page).to have_content("Subject type")
    expect(page).to have_content("Offender")
    expect(page).to have_content("Full name of subject")
    expect(page).to have_content(sar_case.subject_full_name)
  end

  scenario 'creating a SAR internal review case', js: true do
    when_i_start_sar_ir_case_journey
    and_i_try_to_link_an_foi_case
    then_i_shoul_expect_to_see_an_error

    when_i_try_to_link_a_regular_sar_case
    and_test_the_back_link_works
    and_link_a_sar_case
    then_i_should_see_the_linked_sar_case_details_on_the_confirm_page

    when_i_confirm_the_linked_sar_details
    then_i_should_see_the_correct_details_pre_populated_on_the_sar_ir_form

    # form details
    Capybara.find(:css, '#sar_internal_review_sar_ir_subtype_compliance', visible: false).click
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
    expect(page).to have_content("Requestor's proof of ID and other documents")


    expect(page.html).to include("IR of #{sar_case.number} - new sar case #{sar_case.subject_full_name.downcase}")

    click_button 'Create case'

    expect(page).to have_content("Case created successfully")
    expect(page).to have_content("new sar case #{sar_case.subject_full_name.downcase}")
  end
end
