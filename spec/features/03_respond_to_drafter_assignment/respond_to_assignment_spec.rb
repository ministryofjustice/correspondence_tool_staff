require 'rails_helper'

feature 'respond to drafter assignment' do

  given(:kase)  do
    create(
      :assigned_case,
      subject: 'A message about XYZ',
      message: 'I would like to know about XYZ'
    )
  end

  given(:assignment) do
    kase.assignments.detect(&:drafter?)
  end

  background do
    login_as assignment.assignee
  end

  scenario 'kilo accepts assignment' do
    visit edit_case_assignment_path kase, assignment
    expect(page).to have_content kase.number
    expect(page).to have_content kase.subject
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'

    choose 'Accept'
    expect(page).
      to have_selector('#assignment_reasons_for_rejection', visible: false)
    click_button 'Confirm'

    expect(current_path).to eq case_path kase
    expect(assignment.reload.state).to eq 'accepted'
    expect(kase.reload.current_state).to eq 'drafting'
  end

  scenario 'kilo rejects assignment' do
    visit edit_case_assignment_path kase, assignment
    expect(page).to have_content kase.number
    expect(page).to have_content kase.subject
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'
    expect(page).to have_content 'Do you accept this case?'

    choose 'Reject'
    expect(page).
      to have_selector('#assignment_reasons_for_rejection', visible: true)
    fill_in 'Reason for rejecting this case', with: 'This is not for me'
    click_button 'Confirm'
    
    expect(page).to have_content(kase.number)
    expect(page).to have_content(kase.subject)
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'
    expect(page).to have_content 'Your response has been sent'
    expect(page).
      to have_content(
        'This case will be reviewed and assigned the to appropriate unit.'
      )

    expect(page).not_to have_content 'Do you accept this case?'

    expect(Assignment.exists?(assignment.id)).to be false
    expect(kase.reload.current_state).to eq 'unassigned'
  end

  scenario 'kilo rejects assignment but provides no reasons for rejection' do
    visit edit_case_assignment_path kase, assignment
    expect(page).to have_content kase.number
    expect(page).to have_content kase.subject
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'

    choose 'Reject'
    expect(page).
      to have_selector('#assignment_reasons_for_rejection', visible: true)
    click_button 'Confirm'

    expect(current_path).
      to eq accept_or_reject_case_assignment_path kase, assignment
    expect(page.find('#assignment_state_rejected')).to be_checked
    expect(page).
      to have_selector('#assignment_reasons_for_rejection', visible: true)
    expect(Assignment.find(assignment.id).state).to eq 'pending'
    expect(kase.reload.current_state).to eq 'awaiting_responder'
    expect(page).
      to have_content('1 error prevented this form from being submitted')
    expect(page).
      to have_content("Reason for rejecting this case can't be blank")
  end

  scenario 'kilo tries to submit the form without selecting accept / reject' do
    visit edit_case_assignment_path kase, assignment
    expect(page).to have_content kase.number
    expect(page).to have_content kase.subject
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'

    click_button 'Confirm'

    expect(current_path).
      to eq accept_or_reject_case_assignment_path kase, assignment

    expect(page).
      to have_selector('#assignment_reasons_for_rejection', visible: false)
    expect(assignment.state).to eq 'pending'
    expect(kase.reload.current_state).to eq 'awaiting_responder'
    expect(page).
      to have_content('1 error prevented this form from being submitted')
    expect(page).
      to have_content("You must either accept or reject this case")
  end

  scenario 'kilo clicks on a link to an assignment that has been rejected' do
    assignment_id = assignment.id
    assignment.reject "NO thank you"
    visit edit_case_assignment_path kase, assignment_id
    expect(page).to have_content('You have already rejected this case')
  end

end
