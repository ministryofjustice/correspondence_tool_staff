require "rails_helper"

feature "viewing SAR cases" do
  given(:approver)           { create :disclosure_specialist }
  given(:manager)            { find_or_create :disclosure_bmt_user }
  given(:responder)          { find_or_create :sar_responder }
  given(:coworker_responder) do
    create :responder, responding_teams: responder.responding_teams
  end
  given(:another_responder) { create :responder }

  context "when unassigned case" do
    given!(:kase) { create :sar_case }

    scenario "viewing as a manager" do
      login_as manager

      cases_show_page.load id: kase.id

      expect(cases_show_page).to be_displayed(id: kase.id)
      expect(cases_show_page.new_message).to have_add_button
    end

    scenario "viewing as a responder" do
      login_as responder

      cases_show_page.load id: kase.id
      expect(open_cases_page).to be_displayed
      expect(open_cases_page.alert.text).to eq "You are not authorised to view this case."
    end
  end

  context "when assigned case" do
    given!(:kase) { create :accepted_sar, responder: }

    scenario "viewing as a manager" do
      login_as manager

      cases_show_page.load id: kase.id

      expect(cases_show_page).to be_displayed(id: kase.id)
      expect(cases_show_page.new_message).to have_add_button
    end

    scenario "viewing as assigned responder" do
      login_as responder

      cases_show_page.load id: kase.id

      expect(cases_show_page).to be_displayed(id: kase.id)
    end

    scenario "viewing as another responder on the same team" do
      login_as coworker_responder

      cases_show_page.load id: kase.id

      expect(cases_show_page).to be_displayed(id: kase.id)
      expect(cases_show_page.new_message).to have_add_button
    end

    scenario "viewing as another responder on different team" do
      login_as another_responder

      cases_show_page.load id: kase.id

      expect(open_cases_page).to be_displayed
      expect(open_cases_page.alert.text).to eq "You are not authorised to view this case."
    end
  end

  context "when case with both full case details and attachment" do
    given(:request_file) { "#{Faker::Internet.slug}.pdf" }
    given(:kase) do
      create :accepted_sar,
             responder:,
             creator: manager,
             uploaded_request_files: [request_file]
    end

    scenario "displaying case details" do
      login_as responder

      cases_show_page.load id: kase.id

      expect(cases_show_page.request).to have_message
      expect(cases_show_page.request.message.text).to eq kase.message
      expect(cases_show_page.request).to have_attachments
      expect(cases_show_page.request.attachments.count).to eq 1
      expect(cases_show_page.request.attachments[0].collection[0].filename.text).to eq request_file
    end
  end

  describe "when stopped case" do
    context "and allowed to restart the clock" do
      given(:responder_and_team_admin) do
        create :responder_and_team_admin, responding_teams: responder.responding_teams
      end

      given!(:kase) do
        create :pending_dacu_clearance_sar, :stopped,
               approving_team: approver.approving_team,
               approver: approver,
               responder: responder_and_team_admin
      end

      scenario "can restart as a manager, approver or responder_and_team_admin", aggregate_failures: true do
        [manager, approver, responder_and_team_admin].each do |user|
          login_as user

          cases_show_page.load id: kase.id

          expect(cases_show_page).to be_displayed(id: kase.id)
          expect(cases_show_page).to have_restart_the_clock
          expect(cases_show_page.new_message).to have_add_button
        end
      end
    end

    context "and not allowed to restart the clock" do
      given!(:kase) { create :accepted_sar, :stopped, responder: responder }

      scenario "cannot restart as a responder" do
        login_as responder

        cases_show_page.load id: kase.id

        expect(cases_show_page).to be_displayed(id: kase.id)
        expect(cases_show_page).not_to have_restart_the_clock
        expect(cases_show_page.new_message).to have_add_button
      end
    end
  end
end
