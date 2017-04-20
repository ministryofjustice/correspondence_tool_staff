require 'rails_helper'

feature "Top level global navigation" do
  let(:responder)       { create(:responder) }
  let(:manager)         { create(:manager)  }
  let(:managing_team)   { create :managing_team, managers: [manager] }
  let(:dacu)            { create :team_dacu }

  before do
    responder
    dacu
    create(:category, :foi)
  end

  scenario "Visiting the login page" do
    login_page.load
    expect(login_page).to have_no_primary_navigation
  end


  context 'As a manager' do
    background do
      login_as manager
    end

    scenario "Home page should have navigation" do
      cases_page.load
      expect(cases_page).to have_primary_navigation
      expect(cases_page.primary_navigation.active_link[:href]).to eq cases_path
    end

    scenario "New case page should have navigation but no active link" do
      cases_new_page.load
      expect(cases_new_page).to have_primary_navigation
      expect(cases_new_page.primary_navigation).to have_no_active_link
    end

    scenario "New Assignment page should have navigation but no active link" do
      kase = create(:case)
      assignments_new_page.load(id: kase.id)
      expect(assignments_new_page).to have_primary_navigation
      expect(assignments_new_page.primary_navigation).to have_no_active_link
    end

    scenario "Case detail page should have navigation but no active link" do
      kase = create(:case)
      cases_show_page.load(id: kase.id)
      expect(cases_show_page).to have_primary_navigation
      expect(cases_show_page.primary_navigation).to have_no_active_link
    end

    scenario "Case closure page should have navigation but no active link" do
      kase = create(:responded_case,
                    received_date: 21.business_days.ago)
      cases_close_page.load(id: kase.id)
      expect(cases_close_page).to have_primary_navigation
      expect(cases_close_page.primary_navigation).to have_no_active_link
    end

  end



  context 'As a responder' do
    background do
      login_as responder
    end

    scenario "Home page should have navigation" do
      cases_page.load

      expect(cases_page).to have_primary_navigation
      expect(cases_page.primary_navigation.active_link[:href]).to eq cases_path
    end

    scenario "Accept/Reject page should have navigation but no active link" do
      kase = create(
          :assigned_case,
          responding_team: responder.responding_teams.first
      )

      assignments_edit_page.load(case_id: kase.id, id: kase.responder_assignment.id)

      expect(assignments_edit_page).to have_primary_navigation
      expect(assignments_edit_page.primary_navigation).to have_no_active_link
    end

    scenario "Case detail page should have navigation but no active link" do
      kase = create(:assigned_case,
                    responding_team: responder.responding_teams.first
      )

      cases_show_page.load(id: kase.id)

      expect(cases_show_page).to have_primary_navigation
      expect(cases_show_page.primary_navigation).to have_no_active_link
    end

    scenario "Upload response page should have navigation but no active link" do
      kase = create(:assigned_case,
                    responding_team: responder.responding_teams.first
      )

      cases_new_response_upload_page.load(id: kase.id)

      expect(cases_new_response_upload_page).to have_primary_navigation
      expect(cases_new_response_upload_page.primary_navigation).to have_no_active_link
    end

    scenario "Mark as sent page should have navigation but no active link" do
      kase = create(:case_with_response,
                    responder: responder
      )

      cases_respond_page.load(id: kase.id)

      expect(cases_respond_page).to have_primary_navigation
      expect(cases_respond_page.primary_navigation).to have_no_active_link
    end

  end

end
