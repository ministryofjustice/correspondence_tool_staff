require "rails_helper"

# rubocop:disable RSpec/BeforeAfterAll
feature "SAR Internal Review Case can be edited", js: true do
  given(:responder)       { find_or_create(:sar_responder) }
  given(:responding_team) { find_or_create :responding_team, responders: [responder] }
  given(:manager)         { find_or_create :disclosure_bmt_user }
  given(:managing_team)   { find_or_create :managing_team, managers: [manager] }
  given(:approving_team)  { find_or_create :team_dacu_disclosure }
  given(:approver)        { approving_team.users.first }

  given(:outcome_reasons) do
    [find(:outcome_reason, :excess_redacts),
     find(:outcome_reason, :wrong_exemp)]
  end

  let(:sar_ir) { create(:sar_internal_review) }

  let(:approved_sar_ir) do
    create(:approved_sar_internal_review,
           approver:)
  end

  let(:responding_sar_ir) do
    create(:approved_sar_internal_review,
           responder:,
           responding_team:)
  end

  let(:closed_sar_ir) do
    kase = create(:closed_sar_internal_review,
                  responder:,
                  responding_team:,
                  outcome_reasons:,
                  approver:,
                  approving_team:,
                  team_responsible_for_outcome: responding_team,
                  team_responsible_for_outcome_id: responding_team.id,
                  late_team: responding_team)
    appeal_outcome = CaseClosure::AppealOutcome.overturned
    kase.appeal_outcome_id = appeal_outcome.id
    kase.save!
    kase
  end

  let(:new_message) { "This is an updated message" }
  let(:new_name) { "Newthaniel Newname" }
  let(:new_third_party_relationship) { "Barrister" }

  background do
    responding_team
    find_or_create :team_dacu_disclosure
  end

  before(:all) do
    require File.join(Rails.root, "db", "seeders", "case_closure_metadata_seeder")
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  context "when a manager" do
    it "will allow me to edit a SAR IR case details" do
      when_a_manager_logs_in
      and_they_edit_the_case_details(sar_ir)
      then_they_expect_the_new_details_to_be_reflected_on_the_case_show_page
    end

    it "will allow me to edit the details of a case closure" do
      when_a_manager_logs_in
      and_loads_the_case_show_page(closed_sar_ir)
      and_they_edit_case_closure_details
      then_the_changes_are_reflected_on_the_case_show_page
    end
  end

  context "when an approver" do
    it "will allow me to edit a SAR IR case details" do
      when_an_approver_logs_in
      and_they_edit_the_case_details(approved_sar_ir)
      then_they_expect_the_new_details_to_be_reflected_on_the_case_show_page
    end

    it "will allow me to edit the details of a case closure" do
      when_an_approver_logs_in
      and_loads_the_case_show_page(closed_sar_ir)
      and_they_edit_case_closure_details
      then_the_changes_are_reflected_on_the_case_show_page
    end
  end

  context "when a responder" do
    it "won't allow me to edit a SAR IR case details" do
      when_a_responder_logs_in
      and_loads_the_case_show_page(responding_sar_ir)
      they_cannot_edit_the_case
    end

    it "won't allow me to edit the details of a case closure" do
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
    expect(page).not_to have_content("Edit closure details")
  end

  def when_an_approver_logs_in
    login_as approver
    cases_page.load
  end

  def when_a_responder_logs_in
    login_as responder
    cases_page.load
  end

  def and_loads_the_case_show_page(sar_internal_review)
    cases_show_page.load(id: sar_internal_review.id)
  end

  def they_cannot_edit_the_case
    page = case_new_sar_ir_case_details_page
    expect(page).to have_content(responding_sar_ir.number.to_s)
    expect(page).not_to have_content("Edit case details")
  end

  def and_they_edit_case_closure_details
    click_link("Edit closure details")

    cases_edit_closure_page.sar_ir_responsible_for_outcome.disclosure.click
    cases_closure_outcomes_page.sar_ir_outcome_reasons.exessive_redactions.check
    cases_closure_outcomes_page.sar_ir_outcome_reasons.wrong_exemption.check
    cases_edit_closure_page.submit_button.click
  end

  def then_the_changes_are_reflected_on_the_case_show_page
    expect(cases_show_page).to have_content("You have updated the closure details for this case.")
    expect(cases_show_page).to have_content("Excessive redaction(s)")
    expect(cases_show_page).to have_content("Incorrect exemption engaged")
    expect(cases_show_page).to have_content("Business unit responsible for appeal outcome")
    expect(cases_show_page).to have_content("Disclosure BMT")
  end

  def and_they_edit_the_case_details(sar_internal_review)
    cases_show_page.load(id: sar_internal_review.id)
    cases_show_page.case_details.edit_case.click

    page = case_new_sar_ir_case_details_page
    page.fill_in_full_case_details(new_message)
    page.third_party_true.click
    page.fill_in_requestor_name(new_name)
    page.fill_in_third_party_relationship(new_third_party_relationship)
    page.submit_button.click
  end

  def then_they_expect_the_new_details_to_be_reflected_on_the_case_show_page
    expect(page).to have_content("Case updated")
    expect(page).to have_content(new_message)
    expect(page).to have_content(new_name)
    expect(page).to have_content(new_third_party_relationship)
  end
end
# rubocop:enable RSpec/BeforeAfterAll
