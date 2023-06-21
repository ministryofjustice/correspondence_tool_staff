require "rails_helper"

describe "teams/index.html.slim", type: :view do
  let(:manager)      { create :manager }
  let(:business_map) { build_stubbed(:report_type, :r006) }
  let(:reports)      { [business_map] }

  before do
    bg_2 = create :business_group, name: "HMPPS", lead: create(:team_lead, value: "John Smith")
    bg_3 = create :business_group, name: "HMCTS", lead: create(:team_lead, value: "Jane Doe")
    create :directorate, business_group: bg_2
    create :directorate, business_group: bg_2
    create :directorate, business_group: bg_3
  end

  it "displays all business groups" do
    login_as manager
    assign(:teams, BusinessGroup.all)
    assign(:reports, reports)

    render

    teams_index_page.load(rendered)

    page = teams_index_page

    expect(page.heading.text).to eq "Business groups"

    # check data in table is correct
    bg1 = page.row_for_business_group("HMPPS")
    expect(bg1.name.text).to eq "View the details of HMPPS"
    expect(bg1.director_general.text).to eq "John Smith"
    expect(bg1.num_directorates.text).to eq "2"

    bg2 = page.row_for_business_group("HMCTS")
    expect(bg2.name.text).to eq "View the details of HMCTS"
    expect(bg2.director_general.text).to eq "Jane Doe"
    expect(bg2.num_directorates.text).to eq "1"
  end
end
