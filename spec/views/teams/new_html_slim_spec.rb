require "rails_helper"

describe "teams/new.html.slim", type: :view do
  let(:manager) { create :manager }

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  context "when creating a new business group" do
    before do
      login_as manager
      assign(:team, BusinessGroup.new)
      render
      teams_new_page.load(rendered)
    end

    it "displays the new business group page and all its fields" do
      expect(teams_new_page.page_heading.text)
        .to eq "New Business group"

      expect(teams_new_page.business_group_label.text)
        .to eq "Business group"

      expect(teams_new_page.business_group_email_label.text)
        .to eq "Business group email"

      expect(teams_new_page.director_general_label.text)
        .to eq "Director general"

      expect(teams_new_page).to have_no_responding_role_option
      expect(teams_new_page).to have_no_approving_role_option
      expect(teams_new_page).to have_no_managing_role_option

      expect(teams_new_page).to have_submit_button
    end
  end

  context "when creating a new directorate" do
    before do
      login_as manager
      assign(:team, Directorate.new)
      render
      teams_new_page.load(rendered)
    end

    it "displays the new directorate page and all its fields" do
      expect(teams_new_page.page_heading.text)
        .to eq "New Directorate"

      expect(teams_new_page.directorate_label.text)
        .to eq "Directorate"

      expect(teams_new_page.directorate_email_label.text)
        .to eq "Directorate email"

      expect(teams_new_page.director_label.text)
        .to eq "Director"

      expect(teams_new_page).to have_no_responding_role_option
      expect(teams_new_page).to have_no_approving_role_option
      expect(teams_new_page).to have_no_managing_role_option

      expect(teams_new_page).to have_submit_button
    end
  end

  context "when creating a new business unit" do
    before do
      login_as manager
      assign(:team, BusinessUnit.new)
      render
      teams_new_page.load(rendered)
    end

    it "displays the new business unit page and all its fields" do
      expect(teams_new_page.page_heading.text)
        .to eq "New Business unit"

      expect(teams_new_page.business_unit_label.text)
        .to eq "Business unit"

      expect(teams_new_page.business_unit_email_label.text)
        .to eq "Business unit email"

      expect(teams_new_page.deputy_director_label.text)
        .to eq "Deputy director"

      expect(teams_new_page).to have_responding_role_option
      expect(teams_new_page).to have_approving_role_option
      expect(teams_new_page).to have_managing_role_option

      expect(teams_new_page).to have_submit_button
    end
  end
end
