require 'rails_helper'

feature 'editing teams' do
  given(:manager) { create :manager }
  given(:bu)      { create :business_unit }

  # Needs JS to add business areas covered which uses ajax
  scenario 'editing a business unit', js: true do
    bu
    login_as manager

    teams_index_page.load
    business_group_row =
      teams_index_page.row_for_business_group bu.business_group.name
    expect(business_group_row.name.text).to eq(bu.business_group.name)
    business_group_row.name.click
    expect(teams_show_page.heading)
      .to have_copy "You are viewing Business group #{bu.business_group.name}"
    directorate_row = teams_show_page.row_for_directorate bu.directorate.name
    expect(directorate_row.name.text).to eq(bu.directorate.name)
    directorate_row.name.click
    expect(teams_show_page.heading)
      .to have_copy "You are viewing Directorate #{bu.directorate.name}"
    business_unit_row = teams_show_page.row_for_business_unit bu.name
    expect(business_unit_row.name.text).to eq(bu.name)
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

    teams_areas_page.add_area_field.set 'This is another area'
    teams_areas_page.add_button.click
    teams_areas_page.wait_until_existing_areas_visible nil, count: 2
    expect(teams_areas_page.descriptions).to include 'This is another area'

    teams_areas_page.create.click

    expect(teams_show_page.page_heading.heading.text).to eq new_name
    expect(teams_show_page.team_email.text).to eq new_email
    expect(teams_show_page.deputy_director.text).to eq new_lead
  end
end
