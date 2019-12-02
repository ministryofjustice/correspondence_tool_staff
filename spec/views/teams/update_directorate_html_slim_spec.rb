require 'rails_helper'

describe 'teams/move_to_directorate.html.slim', type: :view do
  let(:business_group) { find_or_create :business_group, name: "Admin"}
  let(:origin_directorate) { find_or_create :directorate, name: 'Origin Directorate', business_group: business_group }
  let(:bu) { create :business_unit, directorate: origin_directorate, name: "Admin team" }
  let(:manager)      { create :manager }
  # before(:each) do
  #   @bg_2 = create :business_group, name: 'HMPPS',
  #                  lead: create(:team_lead, value: 'John Smith')
  #   create :directorate, business_group: @bg_2
  #   create :directorate, business_group: @bg_2
  #   @bg_3 = create :business_group, name: 'HMCTS',
  #                  lead: create(:team_lead, value: 'Jane Doe')
  #   create :directorate, business_group: @bg_3
  # end

  it 'displays all business groups' do
    login_as manager
    assign(:directorates, Directorate.all)
    assign(:team, bu)

    render

    teams_move_page.load(rendered)

    page = teams_move_page

    expect(page.heading.text).to eq "Move business unit"
    expect(page.subhead.text).to eq "Business unit: Admin team "

    # check data in table is correct
    dir = page.find_row("DACU Directorate")
    expect(dir).to be_present
    expect(dir.directorate_details.text).to eq "DACU Directorate"
    expect(dir.move_to_directorate_link.text).to eq "Move to this directorate"

    dir = page.find_row("Origin Directorate")
    expect(dir).to be_present
    expect(dir.directorate_details.text).to eq "Origin Directorate"
    expect(dir.text).to have_content "This is where the team is currently located"
  end
end
