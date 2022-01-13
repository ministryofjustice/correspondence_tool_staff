require 'rails_helper'

feature 'SAR Internal Review Case can be closed', js:true do

  given(:responder)       { find_or_create(:sar_responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { find_or_create :disclosure_bmt_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:approver)        { (find_or_create :team_dacu_disclosure).users.first }

  let!(:sar_ir) { create(:ready_to_close_sar_internal_review) }

  let!(:late_sar_ir) { 
    create(:ready_to_close_sar_internal_review, 
            date_responded: Date.today,
            external_deadline: Date.today - 5) 
  }

  background do
    responding_team
    find_or_create :team_dacu_disclosure
  end

  before do
    require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
    CaseClosure::MetadataSeeder.seed!
  end

  context 'as a manager closing a SAR IR' do
    context 'for late case' do
      it 'page loads with correct fields asking who is responsible for lateness' do
        login_as manager
        cases_page.load
        click_link "#{late_sar_ir.number}"
        cases_show_page.actions.close_case.click
        cases_close_page.submit_button.click
        on_load_field_expectations(lateness: true)
      end
    end

    context 'for in-time case' do
      it 'page loads with correct fields asking' do
        login_as manager
        cases_page.load
        click_link "#{sar_ir.number}"
        cases_show_page.actions.close_case.click
        cases_close_page.submit_button.click
        on_load_field_expectations
      end
    end
  end

  def on_load_field_expectations(lateness: false) 
    if lateness
      expect(page).to have_content("Who was responsible for lateness?")
    else
      expect(page).to_not have_content("Who was responsible for lateness?")
    end
    expect(page).to have_content("SAR IR Outcome?")
    expect(page).to have_content("Who was responsible for outcome being partially upheld or overturned?")
    expect(page).to have_content("Was the response asking for missing information (e.g. proof of ID), or clarification, i.e. a TTM?")
  end
end
