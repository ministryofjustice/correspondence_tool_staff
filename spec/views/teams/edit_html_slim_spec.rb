require "rails_helper"

describe "teams/edit.html.slim", type: :view do
  let(:manager)   { create :manager }
  let(:hmpps)     { create_business_group("HMPPS", "Michael Spurr") }
  let(:prisons)   { create_directorate(hmpps, "Prisons", "Phil Copple") }
  let(:ops)       { create_business_unit(prisons, "Operations", "Jack Harris") }

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  context "when editing an existing business group" do
    before do
      login_as manager
      assign(:team, hmpps)
      render
      teams_edit_page.load(rendered)
    end

    it "displays the edit business group page and all its fields" do
      expect(teams_edit_page.page_heading.text)
        .to eq "Edit Business group"

      expect(teams_edit_page.business_group_label.text)
        .to eq "Business group"

      expect(teams_edit_page.name.value)
        .to eq hmpps.name

      expect(teams_edit_page.business_group_email_label.text)
        .to eq "Business group email"

      expect(teams_edit_page.email.value)
        .to eq hmpps.email

      expect(teams_edit_page.director_general_label.text)
        .to eq "Director general"

      expect(teams_edit_page.lead.value)
        .to eq hmpps.properties.lead.first.value

      expect(teams_edit_page).to have_no_responding_role_option
      expect(teams_edit_page).to have_no_approving_role_option
      expect(teams_edit_page).to have_no_managing_role_option

      expect(teams_edit_page).to have_submit_button
    end
  end

  context "when editing an existing directorate" do
    before do
      login_as manager
      assign(:team, prisons)
      render
      teams_edit_page.load(rendered)
    end

    it "displays the edit directorate page and all its fields" do
      expect(teams_edit_page.page_heading.heading.text)
        .to eq "Edit Directorate"

      expect(teams_edit_page.page_heading.sub_heading.text)
        .to eq "Business group: #{hmpps.name} "

      expect(teams_edit_page.directorate_label.text)
        .to eq "Directorate"

      expect(teams_edit_page.name.value)
        .to eq prisons.name

      expect(teams_edit_page.directorate_email_label.text)
        .to eq "Directorate email"

      expect(teams_edit_page.email.value)
        .to eq prisons.email

      expect(teams_edit_page.director_label.text)
        .to eq "Director"

      expect(teams_edit_page.lead.value)
        .to eq prisons.properties.lead.first.value

      expect(teams_edit_page).to have_no_responding_role_option
      expect(teams_edit_page).to have_no_approving_role_option
      expect(teams_edit_page).to have_no_managing_role_option

      expect(teams_edit_page).to have_submit_button
    end
  end

  context "when editing an existing business unit" do
    before do
      login_as manager
      assign(:team, ops)
      render
      teams_edit_page.load(rendered)
    end

    it "displays the new business group page and all its fields" do
      expect(teams_edit_page.page_heading.heading.text)
        .to eq "Edit Business unit"

      expect(teams_edit_page.page_heading.sub_heading.text)
        .to eq "Directorate: #{prisons.name} "

      expect(teams_edit_page.business_unit_label.text)
        .to eq "Business unit"

      expect(teams_edit_page.name.value)
        .to eq ops.name

      expect(teams_edit_page.business_unit_email_label.text)
        .to eq "Business unit email"

      expect(teams_edit_page.email.value)
        .to eq ops.email

      expect(teams_edit_page.deputy_director_label.text)
        .to eq "Deputy director"

      expect(teams_edit_page.lead.value)
        .to eq ops.properties.lead.first.value

      expect(teams_edit_page).to have_no_responding_role_option
      expect(teams_edit_page).to have_no_approving_role_option
      expect(teams_edit_page).to have_no_managing_role_option

      expect(teams_edit_page).to have_submit_button
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
