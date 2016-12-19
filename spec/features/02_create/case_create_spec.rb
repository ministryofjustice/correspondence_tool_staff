require 'rails_helper'

feature 'Case creation' do

  given(:kase) do
    Struct.new('Case', :name, :email, :subject, :message).new(
      'A. Member of Public',
      'member@public.com',
      'FOI - foo bar foo bar',
      'An FOI request from a member of public'
    )
  end

  background do
    create(:category, :foi)
    login_as create(:user)
    visit cases_path
    click_link "New case"
  end

  scenario 'succeeds using valid inputs' do
    expect(current_path).to eq new_case_path
    expect(page).to have_content('New case')
    fill_in 'Full name',          with: kase.name
    fill_in 'Email',              with: kase.email
    fill_in 'Subject of request', with: kase.subject
    fill_in 'Full request',       with: kase.message
    fill_in 'Day',                with: Time.zone.today.day.to_s
    fill_in 'Month',              with: Time.zone.today.month.to_s
    fill_in 'Year',               with: Time.zone.today.year.to_s
    click_button 'Continue'

    new_case = Case.first

    expect(current_path).to eq new_case_assignment_path new_case
    expect(page).to have_content('Case successfully created')

    expect(new_case).to have_attributes(
      name:           kase.name,
      email:          kase.email,
      subject:        kase.subject,
      message:        kase.message,
      received_date:  Time.zone.today
    )

    select User.drafters.first.email, from: 'assignment[assignee_id]'
    click_button 'Create Assignment'
    expect(current_path).to eq cases_path

    new_assignment = Assignment.first

    expect(new_case.reload).to have_attributes(
      state:       'awaiting_drafter',
      assignments: [new_assignment]
    )

    expect(new_assignment).to have_attributes(
      assignment_type: 'drafter',
      assignee:        User.drafters.first,
      assigner:        User.assigners.first,
      case:            new_case,
      state:           'pending'
    )
  end

  scenario 'fails informatively without any inputs' do
    expect(current_path).to eq new_case_path
    expect(page).to have_content('New case')

    click_button 'Continue'

    expect(page).to have_content("Full name can't be blank")
    expect(page).to have_content("Email and postal address can't both be blank")
    expect(page).to have_content("Postal address and email can't both be blank")
    expect(page).to have_content("Subject of request can't be blank")
    expect(page).to have_content("Full request can't be blank")
    expect(page).to have_content("Received date can't be blank")
  end
end
