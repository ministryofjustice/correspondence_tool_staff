require "rails_helper"

describe "teams/join_teams.html.slim", type: :view do
  let(:business_group) { find_or_create :business_group, name: "Admin" }
  let(:origin_directorate) { find_or_create :directorate, name: "Origin Directorate", business_group: }
  let(:bu) { create :business_unit, directorate: origin_directorate, name: "Admin team" }
  let(:manager) { create :manager }
  # before(:each) do
  #   @bg_2 = create :business_group, name: 'HMPPS',
  #                  lead: create(:team_lead, value: 'John Smith')
  #   create :directorate, business_group: @bg_2
  #   create :directorate, business_group: @bg_2
  #   @bg_3 = create :business_group, name: 'HMCTS',
  #                  lead: create(:team_lead, value: 'Jane Doe')
  #   create :directorate, business_group: @bg_3
  # end

  it "displays all business groups" do
    login_as manager
    assign(:directorates, Directorate.all)
    assign(:team, bu)

    render

    teams_join_page.load(rendered)

    page = teams_join_page

    expect(page.heading.text).to eq "Join business unit"
    expect(page.subhead.text).to eq "Business unit: Admin team "
  end
end
