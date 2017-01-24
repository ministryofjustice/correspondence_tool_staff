require 'rails_helper'

feature 'respond to drafter assignment' do

  given(:drafter)         { create(:user, roles: ['drafter']) }

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
    login_as drafter
  end

  scenario 'kilo accepts assignment' do
    visit edit_case_assignment_path kase, assignment
    expect(page).to have_content kase.number
    expect(page).to have_content kase.subject
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'

    choose 'Accept'
    expect(page).to have_selector('#assignment_reasons_for_rejection', visible: false)
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

    choose 'Reject'
    expect(page).to have_selector('#assignment_reasons_for_rejection', visible: true)
    fill_in 'Reason for rejecting this case', with: 'I am not the correct KILO for this'
    click_button 'Confirm'

    expect(current_path).to eq case_path kase
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

    expect(page.find('#assignment_state_rejected')).to be_checked
    expect(page).
      to have_selector('#assignment_reasons_for_rejection', visible: true)
    expect(kase.reload.current_state).to eq 'awaiting_responder'

    expect(page).
      to have_content("Reason for rejecting this case can't be blank")
  end
end
