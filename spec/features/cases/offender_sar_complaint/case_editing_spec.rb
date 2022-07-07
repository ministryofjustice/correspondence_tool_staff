require 'rails_helper'

feature 'offender sar complaint case editing by a manager' do
  given(:manager)         { find_or_create :branston_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:offender_sar_complaint) { create :offender_sar_complaint, :third_party, received_date: 2.weeks.ago.to_date }
  given(:offender_sar_ico_complaint) { 
    create :offender_sar_complaint, :third_party, 
            received_date: 2.weeks.ago.to_date, complaint_type: 'ico_complaint' }
  given(:offender_sar_litigation_complaint) { 
    create :offender_sar_complaint, :third_party, 
            received_date: 2.weeks.ago.to_date, complaint_type: 'litigation_complaint' }

  background do
    CaseClosure::MetadataSeeder.seed!
    find_or_create :team_branston
    login_as manager
    cases_show_page.load(id: offender_sar_complaint.id)
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  scenario 'editing an offender sar complaint case', js: true do
    expect(cases_show_page).to be_displayed(id: offender_sar_complaint.id)
    sleep 10
    cases_show_page.offender_sar_subject_details.change_link.click
    expect(cases_edit_offender_sar_complaint_subject_details_page).to be_displayed

    cases_edit_offender_sar_complaint_subject_details_page.edit_name ''
    click_on "Continue"
    expect(cases_edit_offender_sar_complaint_page).to be_displayed
    expect(cases_edit_offender_sar_complaint_subject_details_page).to have_content("Full name of data subject")
    expect(cases_edit_offender_sar_complaint_subject_details_page).to have_content("What is the location of the data subject?")
    expect(cases_edit_offender_sar_complaint_subject_details_page).to have_content("Subject full name cannot be blank")

    cases_edit_offender_sar_complaint_subject_details_page.edit_name 'Bob Hope'
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_complaint.id)
    expect(cases_show_page).to have_content 'Bob Hope'
    expect(cases_show_page).to have_content 'Case updated'
    expect(cases_show_page).to have_content 'Case details edited'

    cases_show_page.offender_sar_requester_details.change_link.click
    expect(cases_edit_offender_sar_complaint_requester_details_page).to be_displayed
    cases_edit_offender_sar_complaint_requester_details_page.edit_third_party_name 'Bob Hope Superstar'
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_complaint.id)
    expect(cases_show_page).to have_content 'Bob Hope Superstar'
    expect(cases_show_page).to have_content 'Case updated'
    expect(cases_show_page).to have_content 'Case details edited'

    cases_show_page.offender_sar_date_received.change_link.click
    expect(cases_edit_offender_sar_complaint_date_received_page).to be_displayed
    cases_edit_offender_sar_complaint_date_received_page.edit_received_date 1.week.ago.to_date
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_complaint.id)
    expect(cases_show_page).to have_content I18n.l(1.week.ago.to_date, format: :default)
    expect(cases_show_page).to have_content 'Case updated'
    expect(cases_show_page).to have_content 'Case details edited'

    cases_show_page.offender_sar_requested_info.change_link.click
    expect(cases_edit_offender_sar_complaint_requested_info_page).to be_displayed
    cases_edit_offender_sar_complaint_requested_info_page.edit_message "In a hole in the ground there lived a Hobbit."
    click_on "Continue"
    expect(cases_show_page).to be_displayed(id: offender_sar_complaint.id)
    expect(cases_show_page).to have_content "In a hole in the ground there lived a Hobbit."
    expect(cases_show_page).to have_content 'Case updated'
    expect(cases_show_page).to have_content 'Case details edited'
  end

  scenario 'user can edit the date a case was closed' do
    expect(cases_show_page).to be_displayed(id: offender_sar_complaint.id)

    when_i_progress_case_to_a_closed_state
    and_i_add_date_that_the_case_was_responded_to
    then_the_case_show_page_should_be_displayed
    when_i_click_the_response_sent_change_link
    and_i_edit_the_date_response_sent
    then_i_expect_the_new_date_to_be_reflected_on_the_case_show_page
  end

  scenario 'user can edit/update exempt and pages for dispatch counts' do
    expect(cases_show_page).to be_displayed(id: offender_sar_complaint.id)

    when_i_update_the_exempt_pages_count
    then_i_should_see_the_updated_exempt_page_count_on_the_show_page

    when_i_update_the_number_of_final_pages
    then_i_should_see_the_pages_for_dispatch_reflected_on_the_show_page
  end

  scenario 'user can edit the external deadline for standard complaint case' do
    expect(cases_show_page).to be_displayed(id: offender_sar_complaint.id)

    new_external_deadline = offender_sar_complaint.received_date + 21
    when_i_click_external_deadline_change_link
    and_i_edit_the_external_deadline(new_external_deadline)
    then_i_expect_the_new_deadline_to_be_reflected_on_the_case_show_page(new_external_deadline)
  end

  scenario 'user can edit the external deadline for ico complaint case' do
    cases_show_page.load(id: offender_sar_ico_complaint.id)
    expect(cases_show_page).to be_displayed(id: offender_sar_ico_complaint.id)

    new_external_deadline = offender_sar_ico_complaint.received_date + 22
    when_i_click_external_deadline_change_link
    and_i_edit_the_external_deadline(new_external_deadline)
    then_i_expect_the_new_deadline_to_be_reflected_on_the_case_show_page(new_external_deadline)
  end

  scenario 'user can edit the external deadline for ico complaint case' do
    cases_show_page.load(id: offender_sar_litigation_complaint.id)
    expect(cases_show_page).to be_displayed(id: offender_sar_litigation_complaint.id)

    new_external_deadline = offender_sar_ico_complaint.received_date + 24
    when_i_click_the_response_sent_change_link
    and_i_edit_the_external_deadline(new_external_deadline)
    then_i_expect_the_new_deadline_to_be_reflected_on_the_case_show_page(new_external_deadline)
  end

  scenario 'user can edit the the complaint type and and sub type' do
    expect(cases_show_page).to be_displayed(id: offender_sar_complaint.id)
    when_i_progress_the_case_status_past_the_initial_state
    when_i_update_the_complaint_type_to_ico 
    then_i_expect_the_case_status_to_be_reset_to_the_inital_case_state
    and_i_expect_the_ico_contact_details_to_be_visible
    
    when_i_progress_the_case_status_past_the_initial_state
    and_i_update_the_complaint_type_to_litigation
    then_i_expect_the_case_status_to_be_reset_to_the_inital_case_state
    and_i_expect_the_ico_and_litigation_details_to_be_visible

    when_i_progress_the_case_status_past_the_initial_state
    and_i_update_the_litigation_details_but_not_the_type
    then_i_expect_the_case_status_to_be_the_same
  end

  scenario 'user can add/edit approvals for ico complaint case', js: true do
    cases_show_page.load(id: offender_sar_ico_complaint.id)
    expect(cases_show_page).to be_displayed(id: offender_sar_ico_complaint.id)
    click_on 'Requires response'
    expect(cases_show_page).to have_content('Add approval')
    expect(cases_show_page).to have_content('Add outcome')

    when_i_click_add_approval_button
    and_i_tick_some_of_approval_options(
      true, [CaseClosure::ApprovalFlag::ICOOffenderComplaint.first_approval.id])
    then_i_expect_the_result_to_be_reflected_on_the_case_show_page(
      CaseClosure::ApprovalFlag::ICOOffenderComplaint.first_approval.name)

    when_i_click_approval_flags_change_link
    and_i_tick_some_of_approval_options(
      true, [CaseClosure::ApprovalFlag::ICOOffenderComplaint.second_approval.id])
    then_i_expect_the_result_to_be_reflected_on_the_case_show_page(
      CaseClosure::ApprovalFlag::ICOOffenderComplaint.second_approval.name)
  end

  scenario 'user can add/edit approvals for litigation complaint case', js: true do
    cases_show_page.load(id: offender_sar_litigation_complaint.id)
    expect(cases_show_page).to be_displayed(id: offender_sar_litigation_complaint.id)
    click_on 'Requires response'
    click_on 'Mark as ongoing legal case'
    expect(cases_show_page).to have_content('Add approval')
    expect(cases_show_page).to have_content('Add outcome')
    expect(cases_show_page).to have_content('Add costs')

    when_i_click_add_approval_button
    and_i_tick_some_of_approval_options(
      false, [CaseClosure::ApprovalFlag::LitigationOffenderComplaint.fee_approval.id])
    then_i_expect_the_result_to_be_reflected_on_the_case_show_page(
      CaseClosure::ApprovalFlag::LitigationOffenderComplaint.fee_approval.name)

    when_i_click_approval_flags_change_link
    and_i_untick_some_of_approval_options(
      false, [CaseClosure::ApprovalFlag::LitigationOffenderComplaint.fee_approval.id])
    then_i_expect_result_removed_from_the_case_show_page(
      CaseClosure::ApprovalFlag::LitigationOffenderComplaint.fee_approval.name)
  end

  scenario 'user can add/edit appeal_outcome for ico complaint case', js: true do
    cases_show_page.load(id: offender_sar_ico_complaint.id)
    expect(cases_show_page).to be_displayed(id: offender_sar_ico_complaint.id)
    click_on 'Requires response'
    expect(cases_show_page).to have_content('Add approval')
    expect(cases_show_page).to have_content('Add outcome')

    when_i_click_add_appeal_outcome
    and_i_not_tick_appeal_outcome
    expect(cases_show_page).to have_content('Add outcome')
    expect(cases_show_page).to have_content 'No changes were made'

    when_i_click_add_appeal_outcome
    and_i_tick_appeal_outcome(CaseClosure::OffenderComplaintAppealOutcome.upheld)
    then_i_expect_the_result_to_be_reflected_on_the_case_show_page(
      CaseClosure::OffenderComplaintAppealOutcome.upheld.name)

    when_i_click_appeal_outcome_change_link
    and_i_tick_appeal_outcome(CaseClosure::OffenderComplaintAppealOutcome.not_upheld)
    then_i_expect_the_result_to_be_reflected_on_the_case_show_page(
      CaseClosure::OffenderComplaintAppealOutcome.not_upheld.name)
  end

  scenario 'user can add/edit outcome for litigation complaint case', js: true do
    cases_show_page.load(id: offender_sar_litigation_complaint.id)
    expect(cases_show_page).to be_displayed(id: offender_sar_litigation_complaint.id)
    click_on 'Requires response'
    click_on 'Mark as ongoing legal case'
    expect(cases_show_page).to have_content('Add approval')
    expect(cases_show_page).to have_content('Add outcome')
    expect(cases_show_page).to have_content('Add costs')

    when_i_click_add_outcome
    and_i_not_tick_outcome
    expect(cases_show_page).to have_content('Add outcome')
    expect(cases_show_page).to have_content 'No changes were made'

    when_i_click_add_outcome
    and_i_tick_outcome(CaseClosure::OffenderComplaintOutcome.not_succeeded)
    then_i_expect_the_result_to_be_reflected_on_the_case_show_page(
      CaseClosure::OffenderComplaintOutcome.not_succeeded.name)

    when_i_click_outcome_change_link
    and_i_tick_outcome(CaseClosure::OffenderComplaintOutcome.succeeded)
    then_i_expect_the_result_to_be_reflected_on_the_case_show_page(
      CaseClosure::OffenderComplaintOutcome.succeeded.name)
  end

  scenario 'user can add/edit costs for litigation complaint case', js: true do
    cases_show_page.load(id: offender_sar_litigation_complaint.id)
    expect(cases_show_page).to be_displayed(id: offender_sar_litigation_complaint.id)
    click_on 'Requires response'
    click_on 'Mark as ongoing legal case'
    expect(cases_show_page).to have_content('Add approval')
    expect(cases_show_page).to have_content('Add outcome')
    expect(cases_show_page).to have_content('Add costs')

    when_i_click_add_costs
    click_on 'Continue'
    expect(cases_show_page).to have_content 'No changes were made'

    when_i_click_add_costs
    and_i_fill_in_costs(11111.11, 22222.22)
    then_i_expect_the_result_to_be_reflected_on_the_case_show_page("11111.11")
    then_i_expect_the_result_to_be_reflected_on_the_case_show_page("22222.22")

    when_i_click_costs_change_link
    and_i_fill_in_costs(12345.67, 8901234.55)
    then_i_expect_the_result_to_be_reflected_on_the_case_show_page("12345.67")
    then_i_expect_the_result_to_be_reflected_on_the_case_show_page("8901234.55")
  end

  scenario 'Third party info are cleaned after changing third party to data subject ', js: true do
    expect(cases_show_page).to be_displayed(id: offender_sar_complaint.id)
    cases_show_page.offender_sar_requester_details.change_link.click
    expect(cases_edit_offender_sar_complaint_requester_details_page).to be_displayed
    cases_edit_offender_sar_complaint_requester_details_page.choose_third_party_option(false)
    click_on "Continue"
    
    expect(cases_show_page).to be_displayed(id: offender_sar_complaint.id)
    expect(cases_show_page).to have_content "Information requested on someone's behalf? No"
    check_thiry_party_info_are_cleaned(offender_sar_complaint)
  end

  def and_i_expect_the_ico_contact_details_to_be_visible
    expect(cases_show_page).to have_content 'ICO Person'
    expect(cases_show_page).to have_content 'test@email.com'
    expect(cases_show_page).to have_content '123456789'
    expect(cases_show_page).to have_content 'REF123456'
  end

  def and_i_expect_the_ico_and_litigation_details_to_be_visible
    and_i_expect_the_ico_contact_details_to_be_visible
    expect(cases_edit_offender_sar_complaint_type_page).to have_content 'Litigation Person'
    expect(cases_edit_offender_sar_complaint_type_page).to have_content 'test2@email.com'
    expect(cases_edit_offender_sar_complaint_type_page).to have_content '2345670'
    expect(cases_edit_offender_sar_complaint_type_page).to have_content 'REF123607'
  end

  def and_i_update_the_litigation_details_but_not_the_type
    complaint_type_update_options = { 
      name: 'Another Litigation Person',
      email: 'test3@email.com', 
      phone: '098673234',
      reference: 'REF756790567'
    }

    within '.section-complaint-type' do
      click_on 'Change'
    end

    cases_edit_offender_sar_complaint_type_page.edit_complaint_type(
      'litigation',
      complaint_type_update_options
    )

    click_on "Continue"
  end

  def when_i_update_the_exempt_pages_count
    click_on 'Requires data'
    click_on 'Update exempt pages'
    expect(page).to have_content('Update exempt pages')
    fill_in 'offender_sar_complaint_number_exempt_pages', with: '1541'
    click_on 'Continue'
  end

  def when_i_update_the_number_of_final_pages
    click_on 'Update final page count'
    expect(page).to have_content('Update final page count')
    fill_in 'offender_sar_complaint_number_final_pages', with: '2849'
    click_on 'Continue'
  end


  def when_i_progress_the_case_status_past_the_initial_state
    click_on "Requires data"
    click_on "Mark as waiting for data"
    click_on "Mark as ready for vetting"
    click_on "Mark as vetting in progress"
  end

  def and_i_update_the_complaint_type_to_litigation
    complaint_type_update_options = { 
      name: 'Litigation Person',
      email: 'test2@email.com', 
      phone: '2345670',
      reference: 'REF123607'
    }

    within '.section-complaint-type' do
      click_on 'Change'
    end

    cases_edit_offender_sar_complaint_type_page.edit_complaint_type(
      'litigation',
      complaint_type_update_options
    )

    click_on "Continue"
  end

  def when_i_update_the_complaint_type_to_ico
    complaint_type_update_options = { 
      name: 'ICO Person',
      email: 'test@email.com', 
      phone: '123456789',
      reference: 'REF123456'
    }

    within '.section-complaint-type' do
      click_on 'Change'
    end

    cases_edit_offender_sar_complaint_type_page.edit_complaint_type(
      'ico',
      complaint_type_update_options
    )

    click_on "Continue"
  end

  def then_i_expect_the_case_status_to_be_reset_to_the_inital_case_state
    expect(cases_show_page).to have_content "To be assessed"
  end

  def then_i_expect_the_case_status_to_be_the_same 
    expect(cases_show_page).to have_content "Vetting in progress"
  end

  def then_i_should_see_the_updated_exempt_page_count_on_the_show_page
    expect(page).to have_content('1541')
    expect(page).to have_content('Case updated')
  end

  def then_i_should_see_the_pages_for_dispatch_reflected_on_the_show_page
    expect(page).to have_content('2849')
    expect(page).to have_content('Case updated')
  end

  def when_i_progress_case_to_a_closed_state
    click_on "Requires data"
    click_on "Mark as waiting for data"
    click_on "Mark as ready for vetting"
    click_on "Mark as vetting in progress"
    click_on "Mark as ready to copy"
    click_on "Requires response"
    click_on "Close case"
  end

  def and_i_add_date_that_the_case_was_responded_to
    cases_close_page.fill_in_date_responded(offender_sar_complaint.received_date + 10)
    click_on "Continue"
  end

  def then_the_case_show_page_should_be_displayed
    expect(cases_closure_outcomes_page).not_to be_displayed
    expect(cases_show_page).to have_content "You've closed this case"
  end

  def when_i_click_the_response_sent_change_link
    cases_show_page.offender_sar_external_deadline.change_link.click
  end

  def and_i_edit_the_date_response_sent
    expect(page).to have_content('Edit case closure details')
    cases_edit_offender_sar_complaint_date_responded_page.edit_responded_date(offender_sar_complaint.received_date + 5)
    cases_edit_offender_sar_complaint_date_responded_page.continue_button.click
  end

  def then_i_expect_the_new_date_to_be_reflected_on_the_case_show_page
    expect(cases_show_page).to have_content(I18n.l(offender_sar_complaint.received_date + 5, format: :default))
  end

  def when_i_click_external_deadline_change_link
    cases_show_page.offender_sar_external_deadline.change_link.click
  end

  def and_i_edit_the_external_deadline(external_deadline)
    cases_edit_offender_sar_complaint_external_deadline_page.edit_external_deadline(external_deadline)
    cases_edit_offender_sar_complaint_external_deadline_page.continue_button.click
  end

  def then_i_expect_the_new_deadline_to_be_reflected_on_the_case_show_page(external_deadline)
    expect(cases_show_page).to have_content(I18n.l(external_deadline, format: :default))
  end

  def when_i_click_add_approval_button
    click_on "Add approval"
  end

  def and_i_tick_some_of_approval_options(is_ico, choices)
    expect(cases_edit_offender_sar_complaint_approval_flags_page).to be_displayed
    cases_edit_offender_sar_complaint_approval_flags_page.choose_approval_flags(is_ico, choices)

    click_on 'Continue'
  end

  def and_i_untick_some_of_approval_options(is_ico, choices)
    expect(cases_edit_offender_sar_complaint_approval_flags_page).to be_displayed
    cases_edit_offender_sar_complaint_approval_flags_page.unchoose_approval_flags(is_ico, choices)

    click_on 'Continue'
  end

  def then_i_expect_the_result_to_be_reflected_on_the_case_show_page(content)
    expect(cases_show_page).to have_content content
  end

  def then_i_expect_the_result_to_be_reflected_on_the_case_show_page(content)
    expect(cases_show_page).to have_content content
  end

  def then_i_expect_result_removed_from_the_case_show_page(content)
    expect(cases_show_page).to_not have_content content
  end

  def when_i_click_approval_flags_change_link
    cases_show_page.offender_sar_complaint_approval_flags.change_link.click
  end

  def when_i_click_add_appeal_outcome
    click_on "Add outcome"
  end

  def and_i_tick_appeal_outcome(choice)
    expect(cases_edit_offender_sar_complaint_appeal_outcome_page).to be_displayed
    cases_edit_offender_sar_complaint_appeal_outcome_page.choose_appeal_outcome(choice)

    click_on 'Continue'
  end

  def and_i_not_tick_appeal_outcome
    and_i_tick_appeal_outcome(nil)
  end 

  def when_i_click_appeal_outcome_change_link
    cases_show_page.offender_sar_complaint_appeal_outcome.change_link.click
  end

  def when_i_click_add_outcome
    click_on "Add outcome"
  end

  def and_i_tick_outcome(choice)
    expect(cases_edit_offender_sar_complaint_outcome_page).to be_displayed
    cases_edit_offender_sar_complaint_outcome_page.choose_outcome(choice)

    click_on 'Continue'
  end

  def and_i_not_tick_outcome
    and_i_tick_outcome(nil)
  end 

  def when_i_click_outcome_change_link
    cases_show_page.offender_sar_complaint_outcome.change_link.click
  end

  def when_i_click_add_costs
    click_on "Add costs"
  end

  def and_i_fill_in_costs(cost1, cost2)
    expect(cases_edit_offender_sar_complaint_costs_page).to be_displayed
    cases_edit_offender_sar_complaint_costs_page.fill_in_costs(cost1, cost2)

    click_on 'Continue'
  end

  def when_i_click_costs_change_link
    cases_show_page.offender_sar_complaint_costs.change_link.click
  end

  def check_thiry_party_info_are_cleaned(complaint)
    complaint.reload
    expect(complaint.third_party).to eq false
    expect(complaint.third_party_relationship).to eq "" 
    expect(complaint.third_party_company_name).to eq "" 
    expect(complaint.third_party_name).to eq "" 
  end

end
