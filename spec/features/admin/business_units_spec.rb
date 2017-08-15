require 'rails_helper'

feature 'editing teams' do
  given(:manager) { create :manager }
  given(:bu)      { create :business_unit }

  scenario 'editing a business unit' do
    bu
    login_as manager

    teams_index_page.load
    business_group_row =
      teams_index_page.row_for_business_group bu.business_group.name
    expect(business_group_row).to be_present
    business_group_row.name.click
    expect(teams_show_page.heading)
      .to have_text "You are viewing Business group #{bu.business_group.name}"

    directorate_row = teams_show_page.row_for_directorate bu.directorate.name
    expect(directorate_row).to be_present
    directorate_row.name.click
    expect(teams_show_page.heading)
      .to have_text "You are viewing Directorate #{bu.directorate.name}"

    business_unit_row = teams_show_page.row_for_business_unit bu.name
    expect(business_unit_row).to be_present
    business_unit_row.edit.click
    expect(teams_edit_page.page_heading.heading)
      .to have_text 'Edit Business unit'
    expect(teams_edit_page.page_heading.sub_heading)
      .to have_text "Directorate: #{bu.directorate.name}"

    new_name = Faker::Company.name
    new_email = Faker::Internet.email
    new_lead = Faker::Name.name
    teams_edit_page.name.set new_name
    teams_edit_page.email.set new_email
    teams_edit_page.deputy_director.set new_lead
    teams_edit_page.submit_button.click

    business_unit_row = teams_show_page.row_for_business_unit new_name
    expect(business_unit_row.email.text).to eq new_email
    expect(business_unit_row.deputy_director.text).to eq new_lead
  end
end
