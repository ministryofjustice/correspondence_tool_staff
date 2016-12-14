require 'rails_helper'

feature 'Correspondence creation' do

  given(:correspondence) do
    Struct.new('Correspondence', :name, :email, :subject, :message).new(
      'A. Member of Public',
      'member@public.com',
      'FOI - foo bar foo bar',
      'An FOI request from a member of public'
    )
  end

  background do
    create(:category, :foi)
    login_as create(:user)
    visit correspondence_index_path
    click_link "New case"
  end

  scenario 'succeeds using valid inputs' do
    expect(current_path).to eq new_correspondence_path
    expect(page).to have_content('New case')
    fill_in 'Full name',          with: correspondence.name
    fill_in 'Email',              with: correspondence.email
    fill_in 'Email confirmation', with: correspondence.email
    fill_in 'Subject of request', with: correspondence.subject
    fill_in 'Full request',       with: correspondence.message
    fill_in 'Day',                with: Time.zone.today.day.to_s
    fill_in 'Month',              with: Time.zone.today.month.to_s
    fill_in 'Year',               with: Time.zone.today.year.to_s
    click_button 'Continue'

    new_correspondence = Correspondence.first

    expect(current_path).to eq new_correspondence_assignment_path new_correspondence
    expect(page).to have_content('Case successfully created')

    expect(new_correspondence).to have_attributes(
      name:           correspondence.name,
      email:          correspondence.email,
      subject:        correspondence.subject,
      message:        correspondence.message,
      received_date:  Time.zone.today
    )

    select User.drafters.first.email, from: 'assignment[assignee_id]'
    click_button 'Create Assignment'
    expect(current_path).to eq correspondence_index_path

    new_assignment = Assignment.first

    expect(new_correspondence.reload).to have_attributes(
      state:       'awaiting_drafter',
      assignments: [new_assignment]
    )

    expect(new_assignment).to have_attributes(
      assignment_type:  'drafter',
      assignee:         User.drafters.first,
      assigner:         User.assigners.first,
      correspondence:   new_correspondence,
      state:            'pending'
    )
  end

  scenario 'fails informatively without any inputs' do
    expect(current_path).to eq new_correspondence_path
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
