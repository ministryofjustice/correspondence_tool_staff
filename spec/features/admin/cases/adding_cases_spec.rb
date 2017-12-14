require "rails_helper"
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

feature 'adding cases' do
  given(:admin)          { create :admin }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  before do
    CTS.class_eval { @dacu_manager = nil; @dacu_team = nil }
    create :responding_team
    find_or_create :team_dacu
    create :category, :foi

    login_as admin
  end

  scenario 'creating a foi case with the default values' do
    admin_cases_page.load
    admin_cases_page.create_case_button.click
    expect(admin_cases_new_page).to be_displayed
    admin_cases_new_page.submit_button.click
    expect(admin_cases_page).to be_displayed
    expect(admin_cases_page.case_list.count).to eq 1
  end

  scenario 'creating a foi case with specific values' do
    admin_cases_page.load
    admin_cases_page.create_case_button.click
    expect(admin_cases_new_page).to be_displayed
    admin_cases_new_page.full_name.set "Test Name"
    admin_cases_new_page.email.set "test@localhost"
    admin_cases_new_page.make_radio_button_choice('case_requester_type_journalist')
    admin_cases_new_page.subject.set "test subject"
    admin_cases_new_page.full_request.set "test message"
    admin_cases_new_page.received_date.set 1.business_days.ago.to_date.to_s
    admin_cases_new_page.created_at.set 1.business_days.ago.to_date.to_s

    admin_cases_new_page.submit_button.click
    expect(admin_cases_page).to be_displayed
    expect(admin_cases_page.case_list.count).to eq 1
    kase = Case.first
    expect(kase.name).to eq 'Test Name'
    expect(kase.email).to eq 'test@localhost'
    expect(kase.subject).to eq 'test subject'
    expect(kase.message).to eq 'test message'
    expect(kase.received_date).to eq 1.business_days.ago.to_date
  end

  scenario 'creating a foi case flagged for DACU disclosure' do
    admin_cases_page.load
    admin_cases_page.create_case_button.click
    expect(admin_cases_new_page).to be_displayed
    admin_cases_new_page.flag_for_disclosure_specialists.set(true)

    admin_cases_new_page.submit_button.click
    expect(admin_cases_page).to be_displayed
    expect(admin_cases_page.case_list.count).to eq 1
    kase = Case.first
    expect(BusinessUnit.dacu_disclosure).to be_in(kase.approving_teams)
  end

  scenario 'creating a foi case flagged for press office' do
    find_or_create :default_press_officer
    find_or_create :default_private_officer
    admin_cases_page.load
    admin_cases_page.create_case_button.click
    expect(admin_cases_new_page).to be_displayed
    admin_cases_new_page.flag_for_press_office.set(true)

    admin_cases_new_page.submit_button.click
    expect(admin_cases_page).to be_displayed
    expect(admin_cases_page.case_list.count).to eq 1
    kase = Case.first
    expect(BusinessUnit.dacu_disclosure).to be_in(kase.approving_teams)
    expect(BusinessUnit.press_office).to be_in(kase.approving_teams)
    expect(BusinessUnit.private_office).to be_in(kase.approving_teams)
  end

  scenario 'creating a foi case flagged for private office' do
    find_or_create :default_press_officer
    find_or_create :default_private_officer
    admin_cases_page.load
    admin_cases_page.create_case_button.click
    expect(admin_cases_new_page).to be_displayed
    admin_cases_new_page.flag_for_private_office.set(true)

    admin_cases_new_page.submit_button.click
    expect(admin_cases_page).to be_displayed
    expect(admin_cases_page.case_list.count).to eq 1
    kase = Case.first
    expect(BusinessUnit.dacu_disclosure).to be_in(kase.approving_teams)
    expect(BusinessUnit.press_office).to be_in(kase.approving_teams)
    expect(BusinessUnit.private_office).to be_in(kase.approving_teams)
  end

  scenario 'creating a flagged for disclosure case that is pending ds clearance' do
    stub_s3_uploader_for_all_files!
    find_or_create :default_press_officer
    find_or_create :default_private_officer
    admin_cases_page.load
    admin_cases_page.create_case_button.click
    expect(admin_cases_new_page).to be_displayed
    admin_cases_new_page.flag_for_disclosure_specialists.set(true)
    admin_cases_new_page.target_state.select 'pending_dacu_disclosure_clearance'

    admin_cases_new_page.submit_button.click
    expect(admin_cases_page).to be_displayed
    expect(admin_cases_page.case_list.count).to eq 1
    kase = Case.first
    expect(kase.current_state).to eq 'pending_dacu_clearance'
    expect(BusinessUnit.dacu_disclosure).to be_in(kase.approving_teams)
  end

  scenario 'creating a closed foi case' do
    stub_s3_uploader_for_all_files!
    find_or_create :default_press_officer
    find_or_create :default_private_officer
    admin_cases_page.load
    admin_cases_page.create_case_button.click
    expect(admin_cases_new_page).to be_displayed
    admin_cases_new_page.target_state.select 'closed'

    admin_cases_new_page.submit_button.click
    expect(admin_cases_page).to be_displayed
    expect(admin_cases_page.case_list.count).to eq 1
    kase = Case.first
    expect(kase.current_state).to eq 'closed'
  end
end
