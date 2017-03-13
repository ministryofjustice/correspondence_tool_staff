require 'rails_helper'

UserInput = Struct.new(
    'Case',
    :requester_type,
    :name,
    :email,
    :subject,
     :message
  )

feature 'Case creation by an assigner' do

  let(:user_input) do
    UserInput.new(
      'Member of the public',
      'A. Member of Public',
      'member@public.com',
      'FOI - foo bar foo bar',
      'An FOI request from a member of public'
    )
  end

  let(:drafter)   { create(:user, roles: ['drafter'])   }
  let(:assigner)  { create(:user, roles: ['assigner'])  }

  background do
    drafter
    create(:category, :foi)
    login_as assigner
    visit cases_path
    click_link "New case"
  end

  scenario 'succeeds using valid inputs' do
    expect(current_path).to eq new_case_path
    expect(page).to have_content('New case')

    choose user_input.requester_type
    fill_in 'Full name',          with: user_input.name
    fill_in 'Email',              with: user_input.email
    fill_in 'Subject of request', with: user_input.subject
    fill_in 'Full request',       with: user_input.message
    fill_in 'Day',                with: Time.zone.today.day.to_s
    fill_in 'Month',              with: Time.zone.today.month.to_s
    fill_in 'Year',               with: Time.zone.today.year.to_s
    click_button 'Continue'

    new_case = Case.first

    expect(current_path).to eq new_case_assignment_path new_case
    expect(page).to have_content('Create and assign case')

    expect(new_case).to have_attributes(
      requester_type: 'member_of_the_public',
      name:           user_input.name,
      email:          user_input.email,
      subject:        user_input.subject,
      message:        user_input.message,
      received_date:  Time.zone.today
    )

    select drafter.full_name, from: 'assignment[assignee_id]'
    click_button 'Create and assign case'
    expect(current_path).to eq cases_path
    expect(page).to have_content('Case successfully created')

    new_assignment = Assignment.first

    expect(new_case.reload).to have_attributes(
      current_state:       'awaiting_responder',
      assignments:         [new_assignment]
    )

    expect(new_assignment).to have_attributes(
      assignment_type: 'drafter',
      assignee:        drafter,
      assigner:        assigner,
      case:            new_case,
      state:           'pending'
    )
  end

  scenario 'fails informatively without any inputs' do
    expect(current_path).to eq new_case_path
    expect(page).to have_content('New case')

    click_button 'Continue'

    expect(page).to have_content("Type of requester must be selected")
    expect(page).to have_content("Full name can't be blank")
    expect(page).to have_content("Email and address can't both be blank")
    expect(page).to have_content("Address and email can't both be blank")
    expect(page).to have_content("Subject of request can't be blank")
    expect(page).to have_content("Full request can't be blank")
    expect(page).to have_content("Date received can't be blank")
  end

  given(:existing_case) { create(:case) }

  scenario 'fails helpfully case number is duplicated in error' do
    allow_any_instance_of(Case).
      to receive(:next_number).and_return existing_case.number

    choose user_input.requester_type
    fill_in 'Full name',          with: user_input.name
    fill_in 'Email',              with: user_input.email
    fill_in 'Subject of request', with: user_input.subject
    fill_in 'Full request',       with: user_input.message
    fill_in 'Day',                with: Time.zone.today.day.to_s
    fill_in 'Month',              with: Time.zone.today.month.to_s
    fill_in 'Year',               with: Time.zone.today.year.to_s
    click_button 'Continue'

    expect(Case.count).to eq 1
    expect(page).to have_content("An error has occurred and your case could not be created.  Please try again.")
    expect(page).not_to have_content('Number')
  end
end
