require 'rails_helper'

describe 'teams/show.html.slim', type: :view do

  let(:manager)   { create :manager }

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  before(:all) do
    @hmpps      = create_business_group('HMPPS', 'Michael Spurr')
    @prisons    = create_directorate(@hmpps, 'Prisons', 'Phil Copple')
    @ops        = create_business_unit(@prisons, 'Operations', 'Jack Harris')
    @ypt        = create_business_unit(@prisons, 'Young People Team', 'Cathy Rbinson')
    @hr         = create_directorate(@hmpps, 'HR', 'Martin Beecroft')
    @hmpps_hr   = create_business_unit(@hr, 'HMPPS HR', 'Dave Mann')
  end

  after(:all) { DbHousekeeping.clean }

  context 'showing a business group' do
    it 'displays the directorates inside it' do
      login_as manager
      assign(:team, @hmpps)
      assign(:children, [ @prisons, @hr ] )

      render

      teams_show_page.load(rendered)

      expect(teams_show_page.heading.text).to eq 'Business Group: HMPPS'

      # check column headings are correct
      headers = teams_show_page.table_heading
      expect(headers.name.text).to eq 'Name'
      expect(headers.team_leader.text).to eq 'Director'
      expect(headers.num_subteams.text).to eq 'Directorates'

      bg = teams_show_page.team_list[0]
      expect(bg.name.text).to eq 'Prisons'
      expect(bg.team_lead.text).to eq 'Phil Copple'
      expect(bg.num_children.text).to eq '2'
      expect(bg.actions.text).to eq 'Edit'

      bg = teams_show_page.team_list[1]
      expect(bg.name.text).to eq 'HR'
      expect(bg.team_lead.text).to eq 'Martin Beecroft'
      expect(bg.num_children.text).to eq '1'
      expect(bg.actions.text).to eq 'Edit'
    end
  end


  private

  def create_business_group(name, team_lead)
    bg = create :business_group, name: name
    add_team_lead(bg, team_lead)
    bg
  end

  def create_directorate(bg, name, team_lead)
    d = create :directorate, name: name, business_group: bg
    add_team_lead(d, team_lead)
    d
  end

  def create_business_unit(directorate, name, team_lead)
    bu = create :business_unit, name: name, directorate: directorate
    add_team_lead(bu, team_lead)
    bu
  end


  def add_team_lead(team, team_lead)
    TeamProperty.create!(team_id: team.id, key: 'lead', value: team_lead)
  end
end
