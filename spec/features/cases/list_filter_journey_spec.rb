require "rails_helper"
require File.join(Rails.root, "db", "seeders", "case_closure_metadata_seeder")
require File.join(Rails.root, "spec", "site_prism", "support", "helper_methods")

feature "filters whittle down search results" do
  include Features::Interactions
  include PageObjects::Pages::Support

  before(:all) do
    @open_cases = {
      ot_ico_foi_noff_unassigned: { received_date: 3.business_days.ago },
      ot_ico_sar_noff_unassigned: { received_date: 3.business_days.ago },
      sar_noff_draft: { received_date: 9.business_days.ago },
      std_draft_foi: { received_date: 6.business_days.ago },
      std_draft_foi_late: { received_date: 25.business_days.ago },
      std_unassigned_irc: { received_date: 1.business_days.ago },
      std_unassigned_irt: { received_date: 2.business_days.ago },
      trig_responded_foi: { received_date: 7.business_days.ago },
    }
    @closed_cases = {
      std_closed_foi: { received_date: 18.business_days.ago },
      std_closed_irc: { received_date: 17.business_days.ago },
      std_closed_irt: { received_date: 16.business_days.ago },
      trig_closed_foi: { received_date: 15.business_days.ago },
    }
    @all_cases = @open_cases.merge(@closed_cases)
    @setup = StandardSetup.new(only_cases: @all_cases)
  end

  after(:all) do
    DbHousekeeping.clean(seed: false)
  end

  context "when type filter" do
    scenario "filter by internal review for compliance, timeliness", js: true do
      login_step user: @setup.disclosure_bmt_user
      expect(open_cases_page).to be_displayed
      expect(open_cases_page.case_numbers)
        .to match_array expected_case_numbers(*@open_cases.keys)

      filter_on_type_step(page: open_cases_page,
                          types: %w[foi_standard],
                          sensitivity: %w[trigger],
                          expected_cases: [@setup.trig_responded_foi])

      # Now uncheck non-trigger and check trigger
      open_cases_page.remove_filter_on("sensitivity", "trigger")
      filter_on_type_step(page: open_cases_page,
                          sensitivity: %w[non_trigger],
                          expected_cases: [@setup.std_draft_foi_late,
                                           @setup.std_draft_foi])

      # Remove type filter using the crumb
      open_cases_page.filter_crumb_for("FOI - Standard").click

      expect(open_cases_page.case_numbers)
        .to match_array expected_case_numbers(
          :ot_ico_foi_noff_unassigned,
          :ot_ico_sar_noff_unassigned,
          :std_draft_foi,
          :std_draft_foi_late,
          :std_unassigned_irc,
          :std_unassigned_irt,
          :sar_noff_draft,
        )

      open_cases_page.open_filter(:sensitivity)
      expect(open_cases_page.filter_sensitivity_content.non_trigger_checkbox)
        .to be_checked
    end

    scenario "filter by non-offender SAR", js: true do
      login_step user: @setup.disclosure_bmt_user
      expect(open_cases_page).to be_displayed
      expect(open_cases_page.case_numbers)
        .to match_array expected_case_numbers(*@open_cases.keys)

      filter_on_type_step(page: open_cases_page,
                          types: %w[sar_non_offender],
                          expected_cases: [@setup.sar_noff_draft])
    end

    scenario "user without sar permissions is filtering", js: true do
      foi             = find_or_create(:foi_correspondence_type)
      responding_team = create(:business_unit, correspondence_types: [foi])
      user            = create(:user, responding_teams: [responding_team])

      login_step(user:)
      open_cases_page.open_filter("type")
      expect(open_cases_page.filter_type_content).to have_no_sar_non_offender_checkbox
    end

    scenario "filter by ICO Overturned", js: true do
      login_step user: @setup.disclosure_bmt_user
      expect(open_cases_page).to be_displayed
      expect(open_cases_page.case_numbers)
        .to match_array expected_case_numbers(*@open_cases.keys)

      filter_on_type_step(page: open_cases_page,
                          types: %w[overturned_ico],
                          expected_cases: [
                            @setup.ot_ico_foi_noff_unassigned,
                            @setup.ot_ico_sar_noff_unassigned,
                          ])
    end
  end

  context "when open case status filter" do
    scenario "filter by unassigned status", js: true do
      login_step user: @setup.disclosure_bmt_user
      expect(open_cases_page).to be_displayed
      expect(open_cases_page.case_numbers)
        .to match_array expected_case_numbers(*@open_cases.keys)
      open_cases_page.filter_on("open_status", "unassigned")
      expect(open_cases_page.case_numbers).to match_array expected_case_numbers(
        :ot_ico_foi_noff_unassigned,
        :ot_ico_sar_noff_unassigned,
        :std_unassigned_irc,
        :std_unassigned_irt,
      )
      open_cases_page.open_filter(:open_status)
      expect(open_cases_page.filter_open_status_content.unassigned_checkbox)
        .to be_checked

      open_cases_page.filter_crumb_for("Needs reassigning").click

      expect(open_cases_page.case_numbers)
        .to match_array expected_case_numbers(*@open_cases.keys)
      expect(open_cases_page.search_results_count.text).to eq "8 cases found"

      open_cases_page.open_filter(:open_status)
      expect(open_cases_page.filter_open_status_content.unassigned_checkbox)
        .not_to be_checked
    end
  end

  context "when all filters set" do
    before do
      login_step user: @setup.disclosure_bmt_user
      expect(open_cases_page).to be_displayed

      open_cases_page.filter_on("sensitivity", "trigger")
      open_cases_page.filter_on("type", "foi_standard")
      open_cases_page.filter_on(:timeliness, "in_time")
      open_cases_page.filter_on("open_status", "responded")
      open_cases_page.filter_on_deadline(from: Time.zone.today,
                                         to: 15.business_days.from_now)
      @deadline_filter_text = sprintf("Deadline %s - %s", Time.zone.today.strftime("%-d %b %Y"), 15.business_days.from_now.strftime("%-d %b %Y"))
    end

    scenario "clearing individual filters", js: true do
      expect(SearchQuery.count).to eq 6

      expect(open_cases_page.search_results_count.text).to eq "1 case found"
      expect(open_cases_page.filter_crumb_for("FOI - Standard")).to be_present
      expect(open_cases_page.filter_crumb_for("Trigger")).to be_present
      expect(open_cases_page.filter_crumb_for("In time")).to be_present
      expect(open_cases_page.filter_crumb_for("Ready to close")).to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).to be_present

      open_cases_page.filter_crumb_for(@deadline_filter_text).click

      expect(SearchQuery.count).to eq 6
      expect(open_cases_page.search_results_count.text).to eq "1 case found"
      expect(open_cases_page.filter_crumb_for("FOI - Standard")).to be_present
      expect(open_cases_page.filter_crumb_for("Trigger")).to be_present
      expect(open_cases_page.filter_crumb_for("In time")).to be_present
      expect(open_cases_page.filter_crumb_for("Ready to close")).to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).not_to be_present

      open_cases_page.filter_crumb_for("Ready to close").click

      expect(SearchQuery.count).to eq 6
      expect(open_cases_page.search_results_count.text).to eq "1 case found"
      expect(open_cases_page.filter_crumb_for("FOI - Standard")).to be_present
      expect(open_cases_page.filter_crumb_for("Trigger")).to be_present
      expect(open_cases_page.filter_crumb_for("In time")).to be_present
      expect(open_cases_page.filter_crumb_for("Ready to close")).not_to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).not_to be_present

      open_cases_page.filter_crumb_for("In time").click

      expect(SearchQuery.count).to eq 6
      expect(open_cases_page.search_results_count.text).to eq "1 case found"
      expect(open_cases_page.filter_crumb_for("FOI - Standard")).to be_present
      expect(open_cases_page.filter_crumb_for("Trigger")).to be_present
      expect(open_cases_page.filter_crumb_for("In time")).not_to be_present
      expect(open_cases_page.filter_crumb_for("Ready to close")).not_to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).not_to be_present

      open_cases_page.filter_crumb_for("Trigger").click

      expect(SearchQuery.count).to eq 7
      expect(open_cases_page.search_results_count.text).to eq "3 cases found"
      expect(open_cases_page.filter_crumb_for("FOI - Standard")).to be_present
      expect(open_cases_page.filter_crumb_for("Trigger")).not_to be_present
      expect(open_cases_page.filter_crumb_for("In time")).not_to be_present
      expect(open_cases_page.filter_crumb_for("Ready to close")).not_to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).not_to be_present

      open_cases_page.filter_crumb_for("FOI - Standard").click

      expect(SearchQuery.count).to eq 8
      expect(open_cases_page.search_results_count.text).to eq "8 cases found"
      expect(open_cases_page.filter_crumb_for("FOI - Standard")).not_to be_present
      expect(open_cases_page.filter_crumb_for("Trigger")).not_to be_present
      expect(open_cases_page.filter_crumb_for("In time")).not_to be_present
      expect(open_cases_page.filter_crumb_for("Ready to close")).not_to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).not_to be_present
    end

    scenario "clearing all filters", js: true do
      expect(open_cases_page.filter_crumb_for("Ready to close")).to be_present
      expect(open_cases_page.filter_crumb_for("FOI - Standard")).to be_present
      expect(open_cases_page.filter_crumb_for("Trigger")).to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).to be_present

      open_cases_page.click_on "Clear all filters"

      expect(open_cases_page.filter_crumb_for("Ready to close")).not_to be_present
      expect(open_cases_page.filter_crumb_for("FOI - Standard")).not_to be_present
      expect(open_cases_page.filter_crumb_for("Trigger")).not_to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).not_to be_present
    end
  end
end
