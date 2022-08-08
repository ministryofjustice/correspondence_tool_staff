require 'rails_helper'

feature 'Require further action for ICO-SAR responded case' do
  given(:team_dacu)      { find_or_create :team_dacu }
  given(:manager)        { create :manager, managing_teams: [ team_dacu ] }
  given(:responder)      { find_or_create(:foi_responder) }
  given(:kase)           { create(:responded_ico_sar_case, manager: manager, responder: responder) }


  scenario '1 - Send the case back to the responder', js: true do
    login_as manager

    testing_inputs = generate_input_values(kase)
    fill_details_for_require_further_action(kase, testing_inputs)
    validate_results(kase, testing_inputs, "require_further_action_to_responder_team", 'To be accepted')
  end


  scenario '2 - Send the case back to the responding team if the responder has been deactivated', js: true do
    login_as manager
    
    kase.responder.soft_delete
    testing_inputs = generate_input_values(kase)
    fill_details_for_require_further_action(kase, testing_inputs)
    validate_results(kase, testing_inputs, "require_further_action_to_responder_team", 'To be accepted')
  end

  scenario '3 - Require to reassign the case to another team if the responding team has been deactivated', js: true do
    login_as manager
    
    kase.responder.soft_delete
    kase.responding_team.update!(deleted_at: Time.current)
    testing_inputs = generate_input_values(kase)
    fill_details_for_require_further_action(kase, testing_inputs)
    validate_results(kase, testing_inputs, "require_further_action_unassigned", 'Needs reassigning')
  end

  scenario '4 - Validate new deadlines - in the past', js: true do
    login_as manager
    
    testing_inputs = generate_input_values(kase)
    testing_inputs[:interal_deadlinen] = Date.today - 10.day
    testing_inputs[:external_deadline] = Date.today - 5.day
    fill_details_for_require_further_action(kase, testing_inputs)
    validate_error_message_not_in_past
  end

  scenario '4 - Validate new deadlines - internal deadline later than external_deadline', js: true do
    login_as manager
    
    testing_inputs = generate_input_values(kase)
    testing_inputs[:interal_deadlinen] = Date.today + 10.day
    testing_inputs[:external_deadline] = Date.today + 5.day
    fill_details_for_require_further_action(kase, testing_inputs)
    validate_error_message_value_of_deadlines
  end
  
  private 

  def generate_input_values(kase)
    return {
      :testing_message => Faker::Lorem.sentence,
      :upload_file => "#{Faker::Internet.slug}.jpg",
      :original_internal_deadline => kase.internal_deadline, 
      :original_external_deadline => kase.external_deadline,
      :original_date_responded => kase.date_responded,
      :interal_deadlinen => Date.today + 10.day,
      :external_deadline => Date.today + 20.day, 
      :team_name => kase.responding_team.name
    }
  end

  def fill_details_for_require_further_action(kase, test_inputs)
    cases_show_page.load(id: kase.id)
    cases_show_page.actions.require_further_action.click
    expect(cases_ico_sar_record_futher_actoin_page).to be_displayed
    cases_ico_sar_record_futher_actoin_page.upload_file(
      kase: kase,
      file_path: test_inputs[:upload_file]
    )

    cases_ico_sar_record_futher_actoin_page.fill_in_message(test_inputs[:testing_message])
    cases_ico_sar_record_futher_actoin_page.click_on 'Continue'

    expect(cases_ico_sar_require_further_action_page).to be_displayed

    cases_ico_sar_require_further_action_page.fill_in_internal_deadline(test_inputs[:interal_deadlinen])
    cases_ico_sar_require_further_action_page.fill_in_external_deadline(test_inputs[:external_deadline])

    cases_ico_sar_require_further_action_page.click_on 'Continue'
  end

  def validate_results(kase, test_inputs, event_name, post_action_state)
    cases_show_page.load(id: kase.id)
    expect(cases_show_page.case_attachments[0].collection[0].filename.text)
      .to eq test_inputs[:upload_file]
    expect(cases_show_page.case_status.details.copy.text).to eq post_action_state
    
    expect(cases_show_page).to have_text test_inputs[:testing_message]

    event_row = cases_show_page.case_history.rows.first
    expect(event_row.details.text).to have_text I18n.t("event.case/ico.#{event_name}_message", team: test_inputs[:team_name])
    expect(event_row.details.text).to have_text I18n.t("event.#{event_name}_desc")

    case_details = cases_show_page.ico.case_details
    expect(case_details.external_deadline.data.text)
        .to eq test_inputs[:external_deadline].strftime(Settings.default_date_format)
    expect(case_details.internal_deadline.data.text)
        .to eq test_inputs[:interal_deadlinen].strftime(Settings.default_date_format)

    expect(case_details.original_external_deadline.data.text)
        .to eq test_inputs[:original_external_deadline].strftime(Settings.default_date_format)
    expect(case_details.original_internal_deadline.data.text)
        .to eq test_inputs[:original_internal_deadline].strftime(Settings.default_date_format)
    expect(case_details.original_date_responded.data.text)
        .to eq test_inputs[:original_date_responded].strftime(Settings.default_date_format)
  end

  def validate_error_message_not_in_past
    expect(cases_ico_foi_require_further_action_page).to be_displayed
    expect(cases_ico_foi_require_further_action_page).to have_text I18n.t('activerecord.errors.models.case/ico.attributes.external_deadline.past')
    expect(cases_ico_foi_require_further_action_page).to have_text I18n.t('activerecord.errors.models.case/ico.attributes.internal_deadline.past')
  end

  def validate_error_message_value_of_deadlines
    expect(cases_ico_foi_require_further_action_page).to be_displayed
    expect(cases_ico_foi_require_further_action_page).to have_text I18n.t('activerecord.errors.models.case.attributes.internal_deadline.after_external')
    expect(cases_ico_foi_require_further_action_page).to have_text I18n.t('activerecord.errors.models.case.attributes.external_deadline.before_internal')
  end

end
