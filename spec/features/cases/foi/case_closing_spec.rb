require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

feature 'Closing a case' do
  background do
    login_as create(:manager)
  end

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  context 'Reporting timiliness' do
    context 'responded-to in time' do
      given!(:fully_granted_case) { create :responded_case,
                                           received_date: 10.business_days.ago }

      given!(:responded_date) { fully_granted_case
                                          .responded_transitions.last.created_at}

      scenario 'A KILO has responded and an manager closes the case', js:true do
        open_cases_page.load
        close_case(fully_granted_case)

        cases_close_page.fill_in_date_responded(0.business_days.ago)
        cases_close_page.is_info_held.yes.click
        cases_close_page.wait_until_outcome_visible
        cases_close_page.outcome.granted_in_full.click
        cases_close_page.submit_button.click

        show_page = cases_show_page.case_details

        expect(show_page.response_details.date_responded.data.text)
          .to eq 0.business_days.ago.strftime(Settings.default_date_format)
        expect(show_page.response_details.timeliness.data.text)
          .to eq 'Answered in time'
        expect(show_page.response_details.time_taken.data.text)
          .to eq '10 working days'
        expect(show_page.response_details.outcome.data.text)
          .to eq 'Granted in full'
        expect(show_page.response_details).to have_no_refusal_reason
      end
    end

    context 'responded-to late' do
      given!(:fully_granted_case) { create :responded_case,
                                           received_date: 22.business_days.ago }

      given!(:responded_date) { fully_granted_case
                                    .responded_transitions.last.created_at}

      scenario 'the case is responded-to late', js: true do
        open_cases_page.load(timeliness: 'late')
        close_case(fully_granted_case)

        cases_close_page.fill_in_date_responded(0.business_days.ago)
        cases_close_page.is_info_held.yes.click
        cases_close_page.wait_until_outcome_visible
        cases_close_page.outcome.granted_in_full.click
        cases_close_page.submit_button.click

        show_page = cases_show_page.case_details
        expect(show_page.response_details.timeliness.data.text)
          .to eq 'Answered late'
        expect(show_page.response_details.time_taken.data.text)
          .to eq '22 working days'
      end
    end
  end

  context 'checking a previously closed case with an exemption' do
    given(:kase) { create :closed_case, :with_ncnd_exemption }

    scenario 'viewing the response details page' do
      cases_show_page.load(id: kase.id)
      show_page = cases_show_page.case_details.response_details
      expect(show_page.exemptions).to have_text 'Generic absolute exemption'
    end
  end

  context 'Is the information held? "Yes"' do
    given!(:kase) { create :responded_case,
                                         received_date: 10.business_days.ago }

    before do
      open_cases_page.load
      close_case(kase)
    end

    scenario 'granted in full', js:true do
      close_page = cases_close_page
      close_page.fill_in_date_responded(2.business_days.ago)
      close_page.is_info_held.yes.click
      close_page.wait_until_outcome_visible
      close_page.outcome.granted_in_full.click
      expect(close_page).to have_no_exemptions
      close_page.submit_button.click

      expect(cases_show_page).to have_content("You've closed this case")
      expect(cases_show_page.actions.text).to eq "Assign to another team"

      show_page = cases_show_page.case_details.response_details
      expect(show_page.date_responded.data.text)
          .to eq 2.business_days.ago.strftime(Settings.default_date_format)
      expect(show_page.timeliness.data.text)
          .to eq 'Answered in time'
      expect(show_page.time_taken.data.text)
          .to eq '8 working days'
      expect(show_page.info_held.data.text)
          .to eq 'Yes'
      expect(show_page.outcome.data.text)
          .to eq 'Granted in full'
      expect(show_page).to have_no_exemptions
    end

    scenario 'refused in part', js:true do
      close_page = cases_close_page
      close_page.fill_in_date_responded(2.business_days.ago)
      close_page.is_info_held.yes.click
      close_page.wait_until_outcome_visible
      close_page.outcome.refused_in_part.click
      close_page.wait_until_exemptions_visible
      expect(close_page.exemptions).to have_no_s12_exceeded_cost
      expect(close_page).to have_exemptions
      chosen_exemption_text =  select_random_exemption
      close_page.submit_button.click

      expect(cases_show_page).to have_content("You've closed this case")
      expect(cases_show_page.actions.text).to eq "Assign to another team"

      show_page = cases_show_page.case_details.response_details
      expect(show_page.date_responded.data.text)
          .to eq 2.business_days.ago.strftime(Settings.default_date_format)
      expect(show_page.timeliness.data.text)
          .to eq 'Answered in time'
      expect(show_page.time_taken.data.text)
          .to eq '8 working days'
      expect(show_page.info_held.data.text)
          .to eq 'Yes'
      expect(show_page.outcome.data.text)
          .to eq 'Refused in part'
      expect(show_page.exemptions.list.map(&:text))
        .to include chosen_exemption_text
    end

    scenario 'refused fully', js:true do
      close_page = cases_close_page
      close_page.fill_in_date_responded(2.business_days.ago)
      close_page.is_info_held.yes.click
      close_page.wait_until_outcome_visible
      close_page.outcome.refused_fully.click
      close_page.wait_until_exemptions_visible

      expect(close_page.exemptions).to have_s12_exceeded_cost
      expect(close_page).to have_exemptions
      chosen_exemption_text =  select_random_exemption
      close_page.submit_button.click

      expect(cases_show_page).to have_content("You've closed this case")
      expect(cases_show_page.actions.text).to eq "Assign to another team"

      show_page = cases_show_page.case_details.response_details
      expect(show_page.date_responded.data.text)
          .to eq 2.business_days.ago.strftime(Settings.default_date_format)
      expect(show_page.timeliness.data.text)
          .to eq 'Answered in time'
      expect(show_page.time_taken.data.text)
          .to eq '8 working days'
      expect(show_page.info_held.data.text)
          .to eq 'Yes'
      expect(show_page.outcome.data.text)
          .to eq 'Refused fully'
      expect(show_page.exemptions.list.map(&:text))
        .to include chosen_exemption_text
    end
  end

  context 'Is the information held? "No"' do
    given!(:no_info_held_case) { create :responded_case,
                                         received_date: 10.business_days.ago }

    before do
      open_cases_page.load
      close_case(no_info_held_case)
    end

    scenario 'manager marks the response as "no information held"', js:true do
      close_page = cases_close_page
      close_page.fill_in_date_responded(2.business_days.ago)
      close_page.is_info_held.no.click
      expect(close_page).to have_no_outcome
      expect(close_page).to have_no_exemptions
      close_page.submit_button.click

      expect(cases_show_page).to have_content("You've closed this case")
      expect(cases_show_page.actions.text).to eq "Assign to another team"

      show_page = cases_show_page.case_details.response_details
      expect(show_page.date_responded.data.text)
          .to eq 2.business_days.ago.strftime(Settings.default_date_format)
      expect(show_page.timeliness.data.text)
          .to eq 'Answered in time'
      expect(show_page.time_taken.data.text)
          .to eq '8 working days'
      expect(show_page.info_held.data.text)
          .to eq 'No'
      expect(show_page).to have_no_outcome
      expect(show_page).to have_no_exemptions
    end

  end

  context 'Is the information held? "Other"'  do
    given!(:other_info_held_case) { create :responded_case,
                                         received_date: 10.business_days.ago }

    before do
      open_cases_page.load
      close_case(other_info_held_case)
      cases_close_page.fill_in_date_responded(2.business_days.ago)

      cases_close_page.is_info_held.other.click
    end

    scenario 'manager selects Neither Confirm nor deny and an exemption', js:true do
      cases_close_page.other_reasons.ncnd.click
      cases_close_page.wait_until_exemptions_visible

      expect(cases_close_page).to have_exemptions

      chosen_exemption_text =  select_random_exemption

      cases_close_page.submit_button.click

      expect(cases_show_page).to have_content("You've closed this case")

      show_page = cases_show_page.case_details.response_details

      expect(show_page.date_responded.data.text)
        .to eq 2.business_days.ago.strftime(Settings.default_date_format)
      expect(show_page.timeliness.data.text)
        .to eq 'Answered in time'
      expect(show_page.time_taken.data.text)
        .to eq '8 working days'
      expect(show_page.refusal_reason.data.text)
        .to eq 'Neither confirm nor deny (NCND)'
      expect(show_page.exemptions.list.map(&:text))
        .to include chosen_exemption_text

    end

    scenario 'manager selects another reason', js:true do
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
        .to eq 'Answered in time'
      expect(show_page.time_taken.data.text)
        .to eq '8 working days'
      expect(show_page.refusal_reason.data.text)
        .to eq selected_reason
      expect(show_page).to have_no_exemptions
    end
  end

  private

  def select_random_exemption
    excemption_options = cases_close_page.exemptions.exemption_options
    #select a random exemption
    total_number_exemptions = excemption_options.count

    # choose a random exemption, but not exemption[0] because that is not valid for NCND
    random_exemption =  Random.new
                          .rand(1..(total_number_exemptions - 1))

    excemption_options[random_exemption].click

    excemption_options[random_exemption].text
  end

  def close_case(kase)
    expect(cases_page.case_list.last.status.text).to eq 'Ready to close'
    click_link kase.number

    expect(cases_show_page.actions).
      to have_link('Close case', href: close_case_path(kase))
    click_link 'Close case'

    expect(cases_close_page).to have_case_attachments
  end
end
