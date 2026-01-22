require "rails_helper"

feature "when extending a SAR case deadline" do
  include Features::Interactions

  given(:manager)             { find_or_create :disclosure_bmt_user }
  given!(:original_deadline)  { kase.external_deadline }
  given!(:received_date) { kase.received_date }

  context "with a manager" do
    given!(:kase) { freeze_time { create :accepted_sar } }

    scenario "extending a SAR case by 30 days twice then removing extension deadline" do
      # Expected dates for display
      expected_initial_extension_date = get_expected_deadline(2.months.since(received_date)).strftime("%-d %b %Y")
      expected_final_extension_date = get_expected_deadline(3.months.since(received_date)).strftime("%-d %b %Y")

      login_as manager

      # 1. Can extend SAR deadline only
      cases_show_page.load(id: kase.id)
      expect(cases_show_page).to have_extend_sar_deadline
      expect(cases_show_page).not_to have_remove_sar_deadline_extension

      # 2. Extend by 30 days for the first time
      extend_sar_deadline_for(kase:, num_calendar_months: 1) do |page|
        page.extension_period_1_calendar_month.click
      end

      case_deadline_text_to_be(expected_initial_extension_date)

      # 3. Extending again does not give you any extension periods for selection
      extend_sar_deadline_for(kase:, num_calendar_months: 1, reason: "Need even more time") do |page|
        expect(page).not_to have_extension_period_1_calendar_month
        expect(page).to have_text("The deadline for this case will be extended by a further one calendar month.")
      end

      case_deadline_text_to_be(expected_final_extension_date)

      # 4. No longer able to extend
      cases_show_page.load(id: kase.id)
      expect(cases_show_page).not_to have_extend_sar_deadline
      expect(cases_show_page).to have_remove_sar_deadline_extension

      # 5. Remove extension should display initial deadline
      cases_show_page.remove_sar_deadline_extension.click
      expect(cases_show_page).to be_displayed
      case_deadline_text_to_be(original_deadline.strftime("%-d %b %Y"))
    end

    scenario "extending a SAR case by 60 days" do
      # Expected dates for display
      expected_final_extension_date = get_expected_deadline(3.months.since(received_date)).strftime("%-d %b %Y")

      login_as manager

      # 1. Extend by 60 days
      extend_sar_deadline_for(kase:, num_calendar_months: 2) do |page|
        page.extension_period_2_calendar_months.click
      end

      case_deadline_text_to_be(expected_final_extension_date)

      # 2. No longer able to extend
      cases_show_page.load(id: kase.id)
      expect(cases_show_page).not_to have_extend_sar_deadline
      expect(cases_show_page).to have_remove_sar_deadline_extension

      # 3. Trying to extend again displays an error message
      visit new_case_sar_extension_path(kase)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.alert.text).to eq("SAR deadline cannot be extended")
    end
  end

  context "with an approver" do
    given!(:approver) { find_or_create :disclosure_specialist }
    given!(:kase) do
      freeze_time do
        create :accepted_sar,
               :flagged_accepted,
               approver:
      end
    end

    scenario "can extend a SAR deadline" do
      login_as approver

      cases_show_page.load(id: kase.id)

      # 1. Extend by 30 days for the first time
      extend_sar_deadline_for(kase:, num_calendar_months: 1) do |page|
        page.extension_period_1_calendar_month.click
      end

      case_deadline_text_to_be(get_expected_deadline(2.months.since(received_date)).strftime("%-d %b %Y"))
    end
  end

  context "with a responder" do
    given(:responder) { kase.responder }
    given!(:kase)     { freeze_time { create :accepted_sar } }

    scenario "cannot extend a SAR deadline" do
      login_as responder

      # 1. No button to extend deadline
      cases_show_page.load(id: kase.id)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page).not_to have_extend_sar_deadline

      # 2. Unauthorized to extend deadline
      visit new_case_sar_extension_path(kase)
      expect(cases_show_page).to be_displayed
      expect(cases_show_page.alert.text).to eq("SAR deadline cannot be extended")
    end
  end

  context "with multiple roles" do
    given!(:multi_roles) { find_or_create :disclosure_specialist }
    given!(:kase) do
      freeze_time do
        create :accepted_sar,
               :flagged_accepted,
               approver: multi_roles
      end
    end

    scenario "a user who is approver and responder can extend a SAR deadline" do
      multi_roles.team_roles << TeamsUsersRole.new(team: kase.responding_team, role: "responder")
      multi_roles.reload
      login_as multi_roles

      cases_show_page.load(id: kase.id)

      extend_sar_deadline_for(kase:, num_calendar_months: 1) do |page|
        page.extension_period_1_calendar_month.click
      end

      case_deadline_text_to_be(get_expected_deadline(2.months.since(received_date)).strftime("%-d %b %Y"))
    end

    scenario "a user who is manager, approver and responder can extend a SAR deadline" do
      multi_roles.team_roles << TeamsUsersRole.new(team: kase.responding_team, role: "responder")
      multi_roles.team_roles << TeamsUsersRole.new(team: manager.teams.first, role: "manager")
      multi_roles.reload
      login_as multi_roles

      cases_show_page.load(id: kase.id)

      extend_sar_deadline_for(kase:, num_calendar_months: 1) do |page|
        page.extension_period_1_calendar_month.click
      end

      case_deadline_text_to_be(get_expected_deadline(2.months.since(received_date)).strftime("%-d %b %Y"))
    end
  end
end
