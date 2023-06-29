require "rails_helper"

describe "teams/move_to_business_group.html.slim", type: :view do
  let(:origin_business_group) { find_or_create :business_group, name: "Origin business group" }
  let(:directorate) { create :directorate, business_group: origin_business_group, name: "Admin direcorate" }
  let(:manager) { create :manager }

  it "displays all business groups" do
    find_or_create :business_group, name: "New business group"
    login_as manager
    assign(:team, directorate)

    render

    directorates_move_page.load(rendered)

    page = directorates_move_page

    expect(page.heading.text).to eq "Move directorate"
    expect(page.subhead.text).to eq "Directorate: Admin direcorate "

    # check data in table is correct
    dir = page.find_row("Origin business group")
    expect(dir).to be_present
    expect(dir.business_group_details.text).to eq "Origin business group"
    expect(dir.text).to have_content "This is where the team is currently located"

    dir = page.find_row("New business group")
    expect(dir).to be_present
    expect(dir.business_group_details.text).to eq "New business group"
    expect(dir.move_to_business_group_link.text).to eq "Move to New business group"
  end
end
