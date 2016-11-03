require 'rails_helper'

feature 'Correspondence can be created ' do

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
    visit new_correspondence_path
  end

  scenario 'using valid inputs' do
    expect(page).to have_content('New case')
    fill_in 'Full name', with: correspondence.name
    fill_in 'Email', with: correspondence.email
    fill_in 'Email confirmation', with: correspondence.email
    fill_in 'Subject of request', with: correspondence.subject
    fill_in 'Full request', with: correspondence.message
    fill_in 'Day', with: Time.zone.today.day.to_s
    fill_in 'Month', with: Time.zone.today.month.to_s
    fill_in 'Year', with: Time.zone.today.year.to_s
    click_button 'Create'

    expect(current_path).to eq correspondence_index_path
    expect(page).to have_content('Case successfully created')

    new_correspondence = Correspondence.first
    expect(new_correspondence.name).to eq correspondence.name
    expect(new_correspondence.email).to eq correspondence.email
    expect(new_correspondence.subject).to eq correspondence.subject
    expect(new_correspondence.message).to eq correspondence.message
    expect(new_correspondence.received_date).to eq Time.zone.today
  end
end
