require "rails_helper"

describe "teams/show.html.slim", type: :view do
  let(:manager)      { create :manager }
  let(:business_map) { build_stubbed(:report_type, :r006) }
  let(:reports)      { [business_map] }

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  context "when showing a business group" do
    let!(:hmpps) { create_business_group("HMPPS", "Michael Spurr") }
    let!(:prisons) { create_directorate(hmpps, "Prisons", "Phil Copple") }
    let!(:hr) { create_directorate(hmpps, "HR", "Martin Beecroft") }

    before do
      create_business_unit(prisons, "Operations", "Jack Harris")
      create_business_unit(prisons, "Young People Team", "Cathy Robinson")
      create_business_unit(hr, "HMPPS HR", "Dave Mann")
    end

    it "displays the directorates inside it" do
      login_as manager
      assign(:team, hmpps)
      assign(:children, hmpps.children)
      assign(:reports, reports)

      render

      teams_show_page.load(rendered)

      expect(teams_show_page.heading)
        .to have_text "You are viewing Business group HMPPS"

      expect(teams_show_page.heading.text)
        .to have_text "You are viewing Business group HMPPS"
      bg = teams_show_page.row_for_directorate("Prisons")
      expect(bg.name.text).to eq "View the details of Prisons"
      expect(bg.director.text).to eq "Phil Copple"
      expect(bg.num_business_units.text).to eq "2"

      bg = teams_show_page.row_for_directorate("HR")
      expect(bg.name.text).to eq "View the details of HR"
      expect(bg.director.text).to eq "Martin Beecroft"
      expect(bg.num_business_units.text).to eq "1"
    end
  end

  context "when showing a directorate" do
    let(:directorate)   { create :directorate }
    let(:bu1)           { create :business_unit, directorate: }
    let(:bu2)           { create :business_unit, directorate: }

    before do
      login_as manager
      assign(:team, directorate)
      assign(:children, directorate.children.order(:name))
      assign(:reports, reports)
      create(:responder, responding_teams: [bu1])
      create(:responder, responding_teams: [bu2])
      create(:responder, responding_teams: [bu2])
    end

    it "displays the directorate name" do
      render
      teams_show_page.load(rendered)

      expect(teams_show_page.heading)
        .to have_text "You are viewing Directorate #{directorate.name}"
    end

    it "displays the director" do
      render
      teams_show_page.load(rendered)

      expect(teams_show_page.director)
        .to have_text "Director#{directorate.team_lead}"
    end

    it "displays the business units" do
      render
      teams_show_page.load(rendered)

      bu1_row = teams_show_page.row_for_business_unit(bu1.name)
      expect(bu1_row.name.text).to eq bu1.name
      expect(bu1_row.deputy_director.text).to eq bu1.team_lead
      expect(bu1_row.email.text).to eq bu1.email
      expect(bu1_row.num_responders.text).to eq "1"

      bu2_row = teams_show_page.row_for_business_unit(bu2.name)
      expect(bu2_row.name.text).to eq bu2.name
      expect(bu2_row.deputy_director.text).to eq bu2.team_lead
      expect(bu2_row.email.text).to eq bu2.email
      expect(bu2_row.num_responders.text).to eq "2"
    end
  end

  context "when showing a business unit" do
    let(:bu)          { create :business_unit }
    let!(:responder1) { create :responder, responding_teams: [bu] }
    let!(:responder2) { create :responder, responding_teams: [bu] }

    before do
      login_as manager
      assign(:team, bu)
      assign(:reports, reports)
      assign(:active_users, [responder1, responder2])
      assign(:case_counts, { responder1.id => 33, responder2.id => 5 })
    end

    it "displays the business unit name" do
      render
      teams_show_page.load(rendered)

      expect(teams_show_page.heading).to have_text "Business unit #{bu.name}"
    end

    it "displays the deputy director and group email" do
      render
      teams_show_page.load(rendered)

      expect(teams_show_page.deputy_director)
        .to have_text bu.team_lead
    end

    it "displays the information officers" do
      render
      teams_show_page.load(rendered)

      user1 = teams_show_page.information_officers_list.first
      expect(user1.name.text).to eq responder1.full_name
      expect(user1.email.text).to eq responder1.email
      expect(user1.num_cases.text).to eq "33"
      user2 = teams_show_page.information_officers_list.second
      expect(user2.name.text).to eq responder2.full_name
      expect(user2.email.text).to eq responder2.email
      expect(user2.num_cases.text).to eq "5"
    end

    it "displays a button to add new information officers" do
      render
      teams_show_page.load(rendered)

      expect(teams_show_page).to have_new_information_officer_button
      expect(teams_show_page.new_information_officer_button[:href])
        .to eq "/teams/#{bu.id}/users/new?role=responder"
    end
  end

private

  def create_business_group(name, team_lead)
    create :business_group,
           name:,
           lead: create(:team_lead, value: team_lead)
  end

  def create_directorate(business_group, name, team_lead)
    create :directorate,
           name:,
           business_group:,
           lead: create(:team_lead, value: team_lead)
  end

  def create_business_unit(directorate, name, team_lead)
    create :business_unit,
           name:,
           directorate:,
           lead: create(:team_lead, value: team_lead)
  end

  def add_team_lead(team, team_lead)
    TeamProperty.create!(team_id: team.id, key: "lead", value: team_lead)
  end
end
