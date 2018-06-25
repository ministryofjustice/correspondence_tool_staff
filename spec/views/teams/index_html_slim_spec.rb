require 'rails_helper'

describe 'teams/index.html.slim', type: :view do

  let(:manager)   { create :manager }

  before(:each) do
    @bg_2 = create :business_group, name: 'HMPPS',
                   lead: create(:team_lead, value: 'John Smith')
    create :directorate, business_group: @bg_2
    create :directorate, business_group: @bg_2
    @bg_3 = create :business_group, name: 'HMCTS',
                   lead: create(:team_lead, value: 'Jane Doe')
    create :directorate, business_group: @bg_3
  end

  it 'displays all business groups' do
    login_as manager
    assign(:teams, BusinessGroup.all)

    render

    teams_index_page.load(rendered)

    page = teams_index_page

    expect(page.heading.text).to eq "Business groups"

    # check data in table is correct
    bg = page.row_for_business_group('HMPPS')
    expect(bg.name.text).to eq 'View the details of HMPPS'
    expect(bg.director_general.text).to eq 'John Smith'
    expect(bg.num_directorates.text).to eq '2'

    bg = page.row_for_business_group('HMCTS')
    expect(bg.name.text).to eq 'View the details of HMCTS'
    expect(bg.director_general.text).to eq 'Jane Doe'
    expect(bg.num_directorates.text).to eq '1'
  end
end
