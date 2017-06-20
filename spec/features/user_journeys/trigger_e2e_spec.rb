###################################
#
# Trigger
#
###################################

# Manager creates flag case & assigns to kilo team
# KILO accepts case
# KILO uploads response
# DS takes on case
# DS clears case
# KILO marks as response
# Manager view case and closes the case

require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

feature "#trigger cases" do
  given(:responder)       { create(:responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { create(:manager)  }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:disclosure_specialist) { create :disclosure_specialist }
  given!(:team_dacu_disclosure) { create :team_dacu_disclosure }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  background do
    managing_team
    responding_team
    create(:category, :foi)
  end

  scenario "creating, assigning, responding, approving and closing a case", js: true do
    # Manager creates & assigns to kilo
    login_as_manager
    kase = manager_creates_new_flagged_case_and_assigns_it
    kase_number = kase.number

    # KILO accepts case, uploads response
    login_as_responder
    responder_accepts_case(kase_number)
    responder_uploads_response(kase)

    # DACU DS takes on a case and approves response
    login_as_disclosure_specialist
    ds_takes_on_case(kase_number)
    ds_approves_response(kase_number)

    # KILO marks response as sent
    login_as_responder
    responder_marks_as_sent(kase_number)

    # Manager closes the case
    login_as_manager
    manager_views_case(kase_number)
    manager_closes_case
  end


  private

  def login_as_manager
    login_as manager

    open_cases_page.load(timeliness: 'in-time')
  end

  def login_as_responder
    login_as responder

    open_cases_page.load(timeliness: 'in-time')
  end

  def login_as_disclosure_specialist
    login_as disclosure_specialist

    open_cases_page.load(timeliness: 'in-time')
  end

  def manager_creates_new_flagged_case_and_assigns_it
    open_cases_page.new_case_button.click

    cases_new_page.fill_in_case_details

    cases_new_page.choose_flag_for_disclosure_specialists('yes')

    cases_new_page.submit_button.click

    assignments_new_page.choose_assignment_team responding_team

    assignments_new_page.create_and_assign_case.click

    expect(cases_show_page.case_status.details.copy.text).to eq "To be accepted"

    new_case_number = cases_show_page.page_heading.sub_heading
                          .text.to_s.gsub('You are viewing case number ', '')

    Case.where(number: new_case_number).first
  end

  def responder_accepts_case(kase_number)
    open_cases_page.case_list
        .find{ |c| c.number.text.include?(kase_number) }.number.click

    assignments_edit_page.accept_radio.click

    assignments_edit_page.confirm_button.click

    expect(cases_show_page.case_status.details.copy.text).to eq "Draft in progress"
  end

  def responder_uploads_response(kase)
    cases_show_page.actions.upload_response.click

    upload_response_with_action_param(kase, responder, 'upload-flagged')

    cases_show_page.load(id: kase.id)

    expect(cases_show_page.case_status.details.copy.text).to eq "Pending clearance"
  end

  def upload_response_with_action_param(kase, user, action)
    kase.reload

    uploads_key = "uploads/#{kase.id}/responses/#{Faker::Internet.slug}.jpg"

    params = ActionController::Parameters.new(
        {
            "type"=>"response",
            "uploaded_files"=>[uploads_key],
            "id"=>kase.id.to_s,
            "controller"=>"cases",
            "action"=>"upload_responses"}
    )

    rus = ResponseUploaderService.new(kase, user, params, action)

    allow(rus).to receive(:move_uploaded_response)

    allow(rus).to receive(:remove_leftover_upload_files)

    rus.upload!
  end

  def ds_takes_on_case(kase_number)
    open_cases_page.primary_navigation.new_cases.click

    row = incoming_cases_page.case_list
             .find{ |c| c.number.text.include?(kase_number) }

    row.actions.take_on_case.click

    row.actions
        .wait_until_success_message_visible
  end

  def ds_approves_response(kase_number)
    incoming_cases_page.case_list
        .find{ |c| c.number.text.include?(kase_number) }.number.click

    cases_show_page.actions.clear_case.click

    approve_response_page.submit_button.click

    expect(open_cases_page)
        .to have_content("You have cleared case #{ kase_number }")
  end

  def responder_marks_as_sent(kase_number)
    open_cases_page.case_list
        .find{ |c| c.number.text.include?(kase_number) }.number.click

    cases_show_page.actions.mark_as_sent.click

    cases_respond_page.mark_as_sent_button.click

    expect(open_cases_page)
        .to have_content("Response confirmed. The case is now with DACU.")
  end

  def manager_views_case(kase_number)
    open_cases_page.case_list
        .find{ |c| c.number.text.include?(kase_number) }.number.click
  end

  def manager_closes_case
    cases_show_page.actions.close_case.click

    cases_close_page.fill_in_date_responded(Date.today)

    cases_close_page.outcome_radio_button_refused_fully.click

    cases_close_page.wait_until_refusal_visible

    expect(cases_close_page.refusal).to have_no_exemptions

    cases_close_page.refusal.exemption_applied.click

    cases_close_page.refusal.wait_until_exemptions_visible

    expect(cases_close_page.refusal.exemptions.exemption_options.size).to eq 25

    cases_close_page.refusal.exemptions.exemption_options.first.click

    cases_close_page.refusal.exemptions.exemption_options[2].click

    cases_close_page.submit_button.click

    expect(cases_show_page).to have_content("You've closed this case")

    expect(cases_show_page.case_status.details.copy.text).to eq "Case closed"
  end
end
