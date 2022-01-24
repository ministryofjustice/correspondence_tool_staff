require 'rails_helper'

feature 'SAR Internal Review Case can be edited', js:true do

  given(:responder)       { find_or_create(:sar_responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { find_or_create :disclosure_bmt_user }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:approver)        { (find_or_create :team_dacu_disclosure).users.first }

  let(:sar_ir) { create(:sar_internal_review) }

  let(:approved_sar_ir) { 
    create(:approved_sar_internal_review,
           approver: approver) 
  }

  let(:responding_sar_ir) { 
    create(:approved_sar_internal_review,
           responder: responder,
           responding_team: responding_team) 
  }

  let(:closed_sar_ir) {
      create(:closed_sar_internal_review)
  }

  let(:new_message) { 'This is an updated message' }
  let(:new_name) { 'Newthaniel Newname' }
  let(:new_third_party_relationship) { 'Barrister' }

  background do
    responding_team
    find_or_create :team_dacu_disclosure
  end

  context 'as a manager' do
    it 'will allow me to edit a SAR IR case details' do
      when_a_manager_logs_in
      and_they_edit_the_case_details(sar_ir)
      then_they_expect_the_new_details_to_be_reflected_on_the_case_show_page
    end
  end

  context 'as an approver' do
    it 'will allow me to edit a SAR IR case details' do
      when_an_approver_logs_in
      and_they_edit_the_case_details(approved_sar_ir)
      then_they_expect_the_new_details_to_be_reflected_on_the_case_show_page
    end
  end

  context 'as a responder' do
    it 'won\'t allow me to edit a SAR IR case details' do
      when_a_responder_logs_in
      and_loads_the_case_show_page(responding_sar_ir)
      they_cannot_edit_the_case
    end

    fit 'won\'t allow me to edit the details of a case closure' do
      when_a_responder_logs_in
      and_loads_the_case_show_page(closed_sar_ir)
      then_they_should_not_be_able_to_edit_the_case_closure_details
    end
  end

  private

  def when_a_manager_logs_in
    login_as manager
    cases_page.load
  end

  def then_they_should_not_be_able_to_edit_the_case_closure_details
    expect(page).to_not have_content("Edit closure details")
  end

  def when_an_approver_logs_in
    login_as approver
    cases_page.load
  end

  def when_a_responder_logs_in
    login_as responder
    cases_page.load
  end

  def and_loads_the_case_show_page(sar_ir)
    cases_show_page.load(id: sar_ir.id)
  end

  def they_cannot_edit_the_case
    page = case_new_sar_ir_case_details_page
    expect(page).to have_content(responding_sar_ir.number.to_s)
    expect(page).to_not have_content('Edit case details')
  end

  def and_they_edit_case_closure_details(sar_ir)
    cases_show_page.load(id: sar_ir.id)
    click_link("Edit closure details")
  end

  def and_they_edit_the_case_details(sar_ir)
    cases_show_page.load(id: sar_ir.id)
    cases_show_page.case_details.edit_case.click

    page = case_new_sar_ir_case_details_page
    page.fill_in_full_case_details(new_message)
    page.third_party_true.click
    page.fill_in_requestor_name(new_name)
    page.fill_in_third_party_relationship(new_third_party_relationship)
    page.submit_button.click
  end

  def then_they_expect_the_new_details_to_be_reflected_on_the_case_show_page
    expect(page).to have_content('Case updated')
    expect(page).to have_content(new_message)
    expect(page).to have_content(new_name)
    expect(page).to have_content(new_third_party_relationship)
  end
end
