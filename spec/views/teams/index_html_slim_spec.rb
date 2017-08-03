require 'rails_helper'

describe 'teams/index.html.slim', type: :view do

  let(:manager)   { create :manager }

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  before(:each) do
    @bg_2 = create :business_group, name: 'HMPPS'
    TeamProperty.create!(team_id: @bg_2.id, key: 'lead', value: 'John Smith')
    create :directorate, business_group: @bg_2
    create :directorate, business_group: @bg_2
    @bg_3 = create :business_group, name: 'HMCTS'
    TeamProperty.create!(team_id: @bg_3.id, key: 'lead', value: 'Jane Doe')
    create :directorate, business_group: @bg_3
  end

  it 'displays all business groups' do
    login_as manager
    assign(:teams, [@bg_2, @bg_3])

    render

    teams_page.load(rendered)

    # check column headings are correct
    headers = teams_page.table_heading
    expect(headers.name.text).to eq 'Name'
    expect(headers.team_leader.text).to eq 'Director General'
    expect(headers.num_subteams.text).to eq 'Directorates'

    # check data in table is correct
    bg = teams_page.team_list[0]
    expect(bg.name.text).to eq 'HMPPS'
    expect(bg.team_lead.text).to eq 'John Smith'
    expect(bg.num_children.text).to eq '2'
    expect(bg.actions.text).to eq 'Edit'

    bg = teams_page.team_list[1]
    expect(bg.name.text).to eq 'HMCTS'
    expect(bg.team_lead.text).to eq 'Jane Doe'
    expect(bg.num_children.text).to eq '1'
    expect(bg.actions.text).to eq 'Edit'
  end
end
