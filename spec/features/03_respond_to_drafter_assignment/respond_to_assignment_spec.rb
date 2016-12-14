require 'rails_helper'

feature 'respond to drafter assignment' do

  given(:drafter)         { create(:user, roles: ['drafter']) }

  given(:kase)  do
    create(
      :case,
      subject: 'A message about XYZ',
      message: 'I would like to know about XYZ'
    )
  end

  given(:assignment) do
    create(:assignment, assignee_id: drafter.id, case_id: kase.id)
  end

  background do
    login_as drafter
  end

  scenario 'kilo accepts assignment' do
    visit edit_case_assignment_path kase, assignment
    expect(page).to have_content kase.name
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'

    choose 'Accept'
    expect(page).not_to have_content 'Reasons for rejection'
    click_button 'Confirm'

    expect(current_path).to eq case_path kase
    expect(assignment.reload.state).to eq 'accepted'
    expect(kase.reload.state).to eq 'drafting'
  end

  scenario 'kilo rejects assignment' do
    visit edit_case_assignment_path kase, assignment
    expect(page).to have_content kase.name
    expect(page).to have_content 'A message about XYZ'
    expect(page).to have_content 'I would like to know about XYZ'

    choose 'Reject'
    expect(page).to have_content 'Reasons for rejection'
    fill_in 'Reasons for rejection', with: 'I am not the correct KILO for this'
    click_button 'Confirm'

    expect(current_path).to eq case_path kase
    expect(assignment.reload.state).to eq 'rejected'
    expect(kase.reload.state).to eq 'unassigned'
  end
end
