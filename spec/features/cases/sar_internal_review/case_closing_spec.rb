require 'rails_helper'

feature 'SAR Internal Review Case can be closed', js:true do

  given(:responder)       { find_or_create(:sar_responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { find_or_create :disclosure_bmt_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:approver)        { (find_or_create :team_dacu_disclosure).users.first }

  let!(:sar_ir) { create(:ready_to_close_sar_internal_review) }

  let!(:late_sar_ir) { 
    create(:ready_to_close_and_late_sar_internal_review) 
  }

  background do
    responding_team
    find_or_create :team_dacu_disclosure
  end

  before :all do
    require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
    CaseClosure::MetadataSeeder.seed!
  end

  after :all do
    CaseClosure::MetadataSeeder.unseed!
  end

  describe 'as a manager closing a SAR IR' do
    context 'for late case' do
      scenario 'page loads with correct fields asking who is responsible for lateness' do
        login_as manager
        cases_page.load
        click_link "#{late_sar_ir.number}"
        cases_show_page.actions.close_case.click
        cases_close_page.submit_button.click

        on_load_field_expectations(lateness: true)

        cases_closure_outcomes_page.sar_ir_responsible_for_lateness.disclosure.click

        cases_closure_outcomes_page.sar_ir_outcome.upheld_in_part.click

        hidden_fields_expectations

        cases_closure_outcomes_page.sar_ir_responsible_for_outcome.disclosure.click
        cases_closure_outcomes_page.sar_ir_outcome_reasons.check "Excessive redaction(s)", visible: false
        cases_closure_outcomes_page.sar_ir_outcome_reasons.check "Incorrect exemption engaged", visible: false

        cases_closure_outcomes_page.submit_button.click

        expect(cases_show_page).to have_content("You've closed this case")
        expect(cases_show_page).to have_content("Excessive redaction(s)")
        expect(cases_show_page).to have_content("Incorrect exemption engaged")
        expect(cases_show_page).to have_content("Business unit responsible for appeal outcome")
        expect(cases_show_page).to have_content("Disclosure BMT")
      end
    end

    context 'for in-time case' do
      scenario 'page loads with correct fields asking' do
        login_as manager
        cases_page.load
        click_link "#{sar_ir.number}"
        cases_show_page.actions.close_case.click
        cases_close_page.submit_button.click

        on_load_field_expectations

        cases_closure_outcomes_page.sar_ir_outcome.upheld.click

        hidden_fields_expectations(should_be_shown: false)

        cases_closure_outcomes_page.submit_button.click

        expect(cases_show_page).to have_content("You've closed this case")
      end
    end
  end

  private

  def on_load_field_expectations(lateness: false) 
    if lateness
      expect(page).to have_content("Who was responsible for lateness?")
    else
      expect(page).to_not have_content("Who was responsible for lateness?")
    end

    expect(page).to have_content("SAR IR Outcome?")
  end

  def hidden_fields_expectations(should_be_shown: true)
    if should_be_shown
      expect(page).to have_content("Who was responsible for outcome being partially upheld or overturned?")
      expect(page).to have_content("Reason(s) for outcome being partially upheld or overturned?")
    else
      expect(page).to_not have_content("Who was responsible for outcome being partially upheld or overturned?")
      expect(page).to_not have_content("Reason(s) for outcome being partially upheld or overturned?")
    end
  end
end
