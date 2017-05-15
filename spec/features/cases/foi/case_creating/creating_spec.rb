require 'rails_helper'

UserInput = Struct.new(
    'Case',
    :requester_type,
    :name,
    :email,
    :subject,
    :message
  )

feature 'Case creation by a manager' do

  let(:user_input) do
    UserInput.new(
      'Member of the public',
      'A. Member of Public',
      'member@public.com',
      'FOI - foo bar foo bar',
      'An FOI request from a member of public'
    )
  end

  given(:responder)       { create(:responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { create(:manager)  }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:dacu)            { create :team_dacu }

  background do
    responding_team
    dacu
    create :team_dacu_disclosure
    create(:category, :foi)
    login_as manager
    cases_page.load
    cases_page.new_case_button.click
  end

  scenario 'succeeds using valid inputs' do
    expect(cases_new_page).to be_displayed

    choose user_input.requester_type
    fill_in 'Full name',          with: user_input.name
    fill_in 'Email',              with: user_input.email
    fill_in 'Subject of request', with: user_input.subject
    fill_in 'Full request',       with: user_input.message
    fill_in 'Day',                with: Time.zone.today.day.to_s
    fill_in 'Month',              with: Time.zone.today.month.to_s
    fill_in 'Year',               with: Time.zone.today.year.to_s
    choose 'case_flag_for_disclosure_specialists_no'

    click_button 'Next - Assign case'

    new_case = Case.first

    expect(assignments_new_page).to be_displayed

    expect(new_case).to have_attributes(
      requester_type: 'member_of_the_public',
      name:           user_input.name,
      email:          user_input.email,
      subject:        user_input.subject,
      message:        user_input.message,
      received_date:  Time.zone.today
    )

    choose responding_team.name
    click_button 'Assign case'

    expect(cases_show_page).to be_displayed

    expect(cases_show_page.text).to have_content('Case successfully created')

    new_assignment = new_case.responder_assignment

    new_case.reload
    expect(new_case.current_state).to eq 'awaiting_responder'

    expect(new_assignment).to have_attributes(
      role:    'responding',
      team:    responding_team,
      user_id: nil,
      case:    new_case,
      state:   'pending'
    )
  end

  scenario 'creating a case that needs clearance' do
    expect(cases_new_page).to be_displayed

    choose user_input.requester_type
    fill_in 'Full name',          with: user_input.name
    fill_in 'Email',              with: user_input.email
    fill_in 'Subject of request', with: user_input.subject
    fill_in 'Full request',       with: user_input.message
    fill_in 'Day',                with: Time.zone.today.day.to_s
    fill_in 'Month',              with: Time.zone.today.month.to_s
    fill_in 'Year',               with: Time.zone.today.year.to_s
    choose 'case_flag_for_disclosure_specialists_yes'

    click_button 'Next - Assign case'

    new_case = Case.last
    expect(new_case.requires_clearance?).to be true
  end

  scenario 'fails informatively without any inputs' do
    expect(cases_new_page).to be_displayed

    click_button 'Next - Assign case'

    expect(page).to have_content("Type of requester must be selected")
    expect(page).to have_content("Full name can't be blank")
    expect(page).to have_content("Email and address can't both be blank")
    expect(page).to have_content("Address and email can't both be blank")
    expect(page).to have_content("Subject of request can't be blank")
    expect(page).to have_content("Full request can't be blank")
    expect(page).to have_content("Date received can't be blank")
  end

  scenario 'requires choice whether to assign a disclosure specialist' do
    expect(cases_new_page).to be_displayed

    choose user_input.requester_type
    fill_in 'Full name',          with: user_input.name
    fill_in 'Email',              with: user_input.email
    fill_in 'Subject of request', with: user_input.subject
    fill_in 'Full request',       with: user_input.message
    fill_in 'Day',                with: Time.zone.today.day.to_s
    fill_in 'Month',              with: Time.zone.today.month.to_s
    fill_in 'Year',               with: Time.zone.today.year.to_s

    click_button 'Next - Assign case'

    expect(page).to have_content("Does a disclosure specialist need to see this? Please choose yes or no.")
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
    choose 'case_flag_for_disclosure_specialists_no'
    click_button 'Next - Assign case'

    expect(Case.count).to eq 1
    expect(page).to have_content("An error has occurred and your case could not be created.  Please try again.")
    expect(page).not_to have_content('Number')
  end
end
