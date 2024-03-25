require "rails_helper"
require Rails.root.join("db/seeders/case_closure_metadata_seeder")

# rubocop:disable RSpec/BeforeAfterAll
feature "Closing a case" do
  background do
    login_as create(:manager)
  end

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  describe "Reporting timiliness" do
    context "when responded-to in time" do
      given!(:fully_granted_case) do
        freeze_time do
          create :responded_case,
                 received_date: 10.business_days.ago
        end
      end

      given!(:responded_date) do
        fully_granted_case.responded_transitions.last.created_at
      end

      scenario "A KILO has responded and an manager closes the case", js: true do
        freeze_time do
          open_cases_page.load
          close_case(fully_granted_case)

          cases_close_page.fill_in_date_responded(0.business_days.ago)
          cases_close_page.click_on "Continue"

          expect(cases_closure_outcomes_page).to be_displayed
          cases_closure_outcomes_page.is_info_held.yes.click
          cases_closure_outcomes_page.wait_until_outcome_visible
          cases_closure_outcomes_page.outcome.granted_in_full.click
          cases_closure_outcomes_page.submit_button.click

          show_page = cases_show_page.case_details

          expect(show_page.response_details.date_responded.data.text)
            .to eq 0.business_days.ago.strftime(Settings.default_date_format)
          expect(show_page.response_details.timeliness.data.text)
            .to eq "Answered in time"
          expect(show_page.response_details.time_taken.data.text)
            .to eq "11 working days"
          expect(show_page.response_details.outcome.data.text)
            .to eq "Granted in full"
          expect(show_page.response_details).to have_no_refusal_reason
        end
      end
    end

    context "when responded-to late" do
      given!(:fully_granted_case) do
        freeze_time do
          create :responded_case,
                 received_date: 22.business_days.ago
        end
      end

      given!(:responded_date) do
        fully_granted_case.responded_transitions.last.created_at
      end

      scenario "the case is responded-to late", js: true do
        freeze_time do
          open_cases_page.load(timeliness: "late")
          close_case(fully_granted_case)

          cases_close_page.fill_in_date_responded(0.business_days.ago)
          cases_close_page.click_on "Continue"

          expect(cases_closure_outcomes_page).to be_displayed
          cases_closure_outcomes_page.is_info_held.yes.click
          cases_closure_outcomes_page.wait_until_outcome_visible
          cases_closure_outcomes_page.outcome.granted_in_full.click
          cases_closure_outcomes_page.submit_button.click

          show_page = cases_show_page.case_details
          expect(show_page.response_details.timeliness.data.text)
            .to eq "Answered late"
          expect(show_page.response_details.time_taken.data.text)
            .to eq "23 working days"
        end
      end
    end
  end

  context "when checking a previously closed case with an exemption" do
    given(:kase) { create :closed_case, :with_ncnd_exemption }

    scenario "viewing the response details page" do
      cases_show_page.load(id: kase.id)
      show_page = cases_show_page.case_details.response_details
      expect(show_page.exemptions).to have_text "Generic absolute exemption"
    end
  end

  context "when information is held" do
    given!(:kase) do
      freeze_time do
        create :responded_case,
               received_date: 10.business_days.ago
      end
    end

    before do
      open_cases_page.load
      close_case(kase)
    end

    scenario "granted in full", js: true do
      freeze_time do
        close_page = cases_close_page
        close_page.fill_in_date_responded(2.business_days.ago)
        close_page.click_on "Continue"

        expect(cases_closure_outcomes_page).to be_displayed
        cases_closure_outcomes_page.is_info_held.yes.click
        cases_closure_outcomes_page.wait_until_outcome_visible
        cases_closure_outcomes_page.outcome.granted_in_full.click
        expect(cases_closure_outcomes_page).to have_no_exemptions
        cases_closure_outcomes_page.submit_button.click

        expect(cases_show_page).to have_content("You've closed this case")
        expect(cases_show_page.actions).to have_content("Assign to another team")
        expect(cases_show_page.actions).to have_content("Delete case")

        show_page = cases_show_page.case_details.response_details
        expect(show_page.date_responded.data.text)
            .to eq 2.business_days.ago.strftime(Settings.default_date_format)
        expect(show_page.timeliness.data.text)
            .to eq "Answered in time"
        expect(show_page.time_taken.data.text)
            .to eq "9 working days"
        expect(show_page.info_held.data.text)
            .to eq "Yes"
        expect(show_page.outcome.data.text)
            .to eq "Granted in full"
        expect(show_page).to have_no_exemptions
      end
    end

    scenario "refused in part", js: true do
      freeze_time do
        close_page = cases_close_page
        close_page.fill_in_date_responded(2.business_days.ago)
        close_page.click_on "Continue"

        expect(cases_closure_outcomes_page).to be_displayed
        cases_closure_outcomes_page.is_info_held.yes.click
        cases_closure_outcomes_page.wait_until_outcome_visible
        cases_closure_outcomes_page.outcome.refused_in_part.click
        cases_closure_outcomes_page.wait_until_exemptions_visible
        expect(cases_closure_outcomes_page.exemptions).to have_no_s12_exceeded_cost
        expect(cases_closure_outcomes_page).to have_exemptions
        chosen_exemption_text = select_random_exemption
        cases_closure_outcomes_page.submit_button.click

        expect(cases_show_page).to have_content("You've closed this case")
        expect(cases_show_page.actions).to have_content("Assign to another team")
        expect(cases_show_page.actions).to have_content("Delete case")

        show_page = cases_show_page.case_details.response_details
        expect(show_page.date_responded.data.text)
            .to eq 2.business_days.ago.strftime(Settings.default_date_format)
        expect(show_page.timeliness.data.text)
            .to eq "Answered in time"
        expect(show_page.time_taken.data.text)
            .to eq "9 working days"
        expect(show_page.info_held.data.text)
            .to eq "Yes"
        expect(show_page.outcome.data.text)
            .to eq "Refused in part"
        expect(show_page.exemptions.list.map(&:text))
          .to include chosen_exemption_text
      end
    end

    scenario "refused fully", js: true do
      freeze_time do
        close_page = cases_close_page
        close_page.fill_in_date_responded(2.business_days.ago)
        close_page.click_on "Continue"

        expect(cases_closure_outcomes_page).to be_displayed
        cases_closure_outcomes_page.is_info_held.yes.click
        cases_closure_outcomes_page.wait_until_outcome_visible
        cases_closure_outcomes_page.outcome.refused_fully.click
        cases_closure_outcomes_page.wait_until_exemptions_visible

        expect(cases_closure_outcomes_page.exemptions).to have_s12_exceeded_cost
        expect(cases_closure_outcomes_page).to have_exemptions
        chosen_exemption_text = select_random_exemption
        cases_closure_outcomes_page.submit_button.click

        expect(cases_show_page).to have_content("You've closed this case")
        expect(cases_show_page.actions).to have_content("Assign to another team")
        expect(cases_show_page.actions).to have_content("Delete case")

        show_page = cases_show_page.case_details.response_details
        expect(show_page.date_responded.data.text)
            .to eq 2.business_days.ago.strftime(Settings.default_date_format)
        expect(show_page.timeliness.data.text)
            .to eq "Answered in time"
        expect(show_page.time_taken.data.text)
            .to eq "9 working days"
        expect(show_page.info_held.data.text)
            .to eq "Yes"
        expect(show_page.outcome.data.text)
            .to eq "Refused fully"
        expect(show_page.exemptions.list.map(&:text))
          .to include chosen_exemption_text
      end
    end
  end

  context "when the information is not held" do
    given!(:no_info_held_case) do
      freeze_time do
        create :responded_case,
               received_date: 10.business_days.ago
      end
    end

    before do
      open_cases_page.load
      close_case(no_info_held_case)
    end

    scenario 'manager marks the response as "no information held"', js: true do
      freeze_time do
        close_page = cases_close_page
        close_page.fill_in_date_responded(2.business_days.ago)
        close_page.click_on "Continue"

        expect(cases_closure_outcomes_page).to be_displayed
        cases_closure_outcomes_page.is_info_held.no.click
        expect(cases_closure_outcomes_page).to have_no_outcome
        expect(cases_closure_outcomes_page).to have_no_exemptions
        cases_closure_outcomes_page.submit_button.click

        expect(cases_show_page).to have_content("You've closed this case")
        expect(cases_show_page.actions).to have_content("Assign to another team")
        expect(cases_show_page.actions).to have_content("Delete case")

        show_page = cases_show_page.case_details.response_details
        expect(show_page.date_responded.data.text)
            .to eq 2.business_days.ago.strftime(Settings.default_date_format)
        expect(show_page.timeliness.data.text)
            .to eq "Answered in time"
        expect(show_page.time_taken.data.text)
            .to eq "9 working days"
        expect(show_page.info_held.data.text)
            .to eq "No"
        expect(show_page).to have_no_outcome
        expect(show_page).to have_no_exemptions
      end
    end
  end

  context "when the information held is Other" do
    given!(:other_info_held_case) do
      freeze_time do
        create :responded_case,
               received_date: 10.business_days.ago
      end
    end

    before do
      freeze_time do
        open_cases_page.load
        close_case(other_info_held_case)
        cases_close_page.fill_in_date_responded(2.business_days.ago)
        cases_close_page.click_on "Continue"

        expect(cases_closure_outcomes_page).to be_displayed # rubocop:disable RSpec/ExpectInHook
        cases_closure_outcomes_page.is_info_held.other.click
      end
    end

    scenario "manager selects Neither Confirm nor deny and an exemption", js: true do
      freeze_time do
        cases_close_page.other_reasons.ncnd.click
        cases_close_page.wait_until_exemptions_visible

        expect(cases_close_page).to have_exemptions

        chosen_exemption_text = select_random_exemption

        cases_close_page.submit_button.click

        expect(cases_show_page).to have_content("You've closed this case")

        show_page = cases_show_page.case_details.response_details

        expect(show_page.date_responded.data.text)
          .to eq 2.business_days.ago.strftime(Settings.default_date_format)
        expect(show_page.timeliness.data.text)
          .to eq "Answered in time"
        expect(show_page.time_taken.data.text)
          .to eq "9 working days"
        expect(show_page.refusal_reason.data.text)
          .to eq "Neither confirm nor deny (NCND)"
        expect(show_page.exemptions.list.map(&:text))
          .to include chosen_exemption_text
      end
    end

    scenario "manager selects another reason", js: true do
      freeze_time do
        other_reasons = cases_close_page.other_reasons.options[1]
        selected_reason = other_reasons.text
        other_reasons.click

        expect(cases_close_page).to have_no_exemptions

        cases_close_page.submit_button.click

        expect(cases_show_page).to have_content("You've closed this case")

        show_page = cases_show_page.case_details.response_details

        expect(show_page.date_responded.data.text)
          .to eq 2.business_days.ago.strftime(Settings.default_date_format)
        expect(show_page.timeliness.data.text)
          .to eq "Answered in time"
        expect(show_page.time_taken.data.text)
          .to eq "9 working days"
        expect(show_page.refusal_reason.data.text)
          .to eq selected_reason
        expect(show_page).to have_no_exemptions
      end
    end
  end

private

  def close_case(kase)
    freeze_time do
      expect(cases_page.case_list.last.status.text).to eq "Ready to close"
      click_link kase.number

      expect(cases_show_page)
        .to have_link("Close case", href: close_case_foi_standard_path(kase))
      click_link "Close case"

      expect(cases_close_page).to have_case_attachments
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
