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

    login_as admin
  end

  context 'Case::FOI::Standard' do
    scenario 'creating a case with the default values' do
      admin_cases_page.load
      admin_cases_page.create_case_button.click
      admin_cases_new_page.create_link_for_correspondence('FOI').click
      admin_cases_new_foi_page.submit_button.click
      expect(admin_cases_page).to be_displayed
      expect(admin_cases_page.case_list.count).to eq 1
    end

    scenario 'creating a case with specific values' do
      admin_cases_page.load

      admin_cases_page.create_case_button.click
      # expect(admin_cases_new_page).to be_displayed
      admin_cases_new_page.create_link_for_correspondence('FOI').click
      expect(admin_cases_new_foi_page).to be_displayed
      admin_cases_new_foi_page.full_name.set "Test Name"
      admin_cases_new_foi_page.email.set "test@localhost"
      admin_cases_new_foi_page.make_radio_button_choice('case_foi_type_casefoistandard')
      admin_cases_new_foi_page.subject.set "test subject"
      admin_cases_new_foi_page.full_request.set "test message"
      admin_cases_new_foi_page.received_date.set 1.business_days.ago.to_date.to_s
      admin_cases_new_foi_page.created_at.set 1.business_days.ago.to_date.to_s

      admin_cases_new_foi_page.submit_button.click
      expect(admin_cases_page).to be_displayed
      expect(admin_cases_page.case_list.count).to eq 1
      kase = Case::FOI::Standard.first
      expect(kase.name).to eq 'Test Name'
      expect(kase.email).to eq 'test@localhost'
      expect(kase.subject).to eq 'test subject'
      expect(kase.message).to eq 'test message'
      expect(kase.received_date).to eq 1.business_days.ago.to_date
      expect(kase.current_state).to eq 'drafting'
    end

    scenario 'creating a case flagged for DACU disclosure' do
      kase = create_foi(case_type: 'case_foi_type_casefoistandard', target_state: 'drafting', flag: 'disclosure')
      expect(kase).to be_instance_of(Case::FOI::Standard)
      expect(kase.current_state).to eq 'drafting'
      expect(BusinessUnit.dacu_disclosure).to be_in(kase.approving_teams)
    end

    scenario 'creating a case flagged for press office' do
      kase = create_foi(case_type: 'case_foi_type_casefoistandard', target_state: 'drafting', flag: 'private')
      expect(kase).to be_instance_of(Case::FOI::Standard)
      expect(kase.current_state).to eq 'drafting'
      expect(BusinessUnit.dacu_disclosure).to be_in(kase.approving_teams)
      expect(BusinessUnit.press_office).to be_in(kase.approving_teams)
      expect(BusinessUnit.private_office).to be_in(kase.approving_teams)
    end

    scenario 'creating a case flagged for private office' do
      kase = create_foi(case_type: 'case_foi_type_casefoistandard', target_state: 'drafting', flag: 'private')
      expect(kase).to be_instance_of(Case::FOI::Standard)
      expect(kase.current_state).to eq 'drafting'
      expect(BusinessUnit.dacu_disclosure).to be_in(kase.approving_teams)
      expect(BusinessUnit.press_office).to be_in(kase.approving_teams)
      expect(BusinessUnit.private_office).to be_in(kase.approving_teams)
    end

    xscenario 'creating a flagged for disclosure case that is pending ds clearance' do
      kase = create_foi(case_type: 'case_foi_type_casefoistandard', target_state: 'pending_dacu_disclosure', flag: 'disclosure')
      expect(kase).to be_instance_of(Case::FOI::Standard)
      expect(kase.current_state).to eq 'pending_dacu_clearance'
      expect(BusinessUnit.dacu_disclosure).to be_in(kase.approving_teams)
    end

    scenario 'creating a closed case', js: true do
      kase = create_foi(case_type: 'case_foi_type_casefoistandard', target_state: 'closed')
      expect(kase).to be_instance_of(Case::FOI::Standard)
      expect(kase.current_state).to eq 'closed'
    end

    scenario 'creating a responded case', js: true do
      kase = create_foi(case_type: 'case_foi_type_casefoistandard', target_state: 'responded')
      expect(kase).to be_instance_of(Case::FOI::Standard)
      expect(kase.current_state).to eq 'responded'
    end
  end

  context 'Case::FOI::TimelinessReview' do
    scenario 'creating a closed case', js: true do
      kase = create_foi(case_type: 'case_foi_type_casefoitimelinessreview', target_state: 'closed')
      expect(kase).to be_instance_of(Case::FOI::TimelinessReview)
      expect(kase.current_state).to eq 'closed'
    end

    scenario 'creating a responded case' do
      kase = create_foi(case_type: 'case_foi_type_casefoitimelinessreview', target_state: 'responded')
      expect(kase).to be_instance_of(Case::FOI::TimelinessReview)
      expect(kase.current_state).to eq 'responded'
    end
  end

  context 'Case::FOI::ComplianceReview' do
    scenario 'creating a closed case', js: true do
      kase = create_foi(case_type: 'case_foi_type_casefoicompliancereview', target_state: 'closed')
      expect(kase).to be_instance_of(Case::FOI::ComplianceReview)
      expect(kase.current_state).to eq 'closed'
    end

    scenario 'creating a responded case' do
      kase = create_foi(case_type: 'case_foi_type_casefoicompliancereview', target_state: 'responded')
      expect(kase).to be_instance_of(Case::FOI::ComplianceReview)
      expect(kase.current_state).to eq 'responded'
    end
  end

  context 'Case::SAR' do
    scenario 'creating a case with the default values' do
      admin_cases_page.load
      admin_cases_page.create_case_button.click
      admin_cases_new_page.create_link_for_correspondence('SAR').click
      admin_cases_new_sar_page.submit_button.click
      expect(admin_cases_page).to be_displayed
      expect(admin_cases_page.case_list.count).to eq 1
    end

    scenario 'creating a case with specific values' do
      admin_cases_page.load

      admin_cases_page.create_case_button.click
      admin_cases_new_page.create_link_for_correspondence('SAR').click
      expect(admin_cases_new_sar_page).to be_displayed
      admin_cases_new_sar_page.make_radio_button_choice('case_sar_reply_method_send_by_email')
      admin_cases_new_sar_page.subject_full_name.set "Test Name"
      admin_cases_new_sar_page.email.set "test@localhost"
      admin_cases_new_sar_page.make_radio_button_choice('case_sar_third_party_false')

      admin_cases_new_sar_page.subject.set "test subject"
      admin_cases_new_sar_page.full_request.set "test message"
      admin_cases_new_sar_page.received_date.set 1.business_days.ago.to_date.to_s
      admin_cases_new_sar_page.created_at.set 1.business_days.ago.to_date.to_s

      admin_cases_new_sar_page.submit_button.click
      expect(admin_cases_page).to be_displayed
      expect(admin_cases_page.case_list.count).to eq 1
      kase = Case::SAR.first
      expect(kase.name).to eq 'Test Name'
      expect(kase.email).to eq 'test@localhost'
      expect(kase.subject).to eq 'test subject'
      expect(kase.message).to eq 'test message'
      expect(kase.received_date).to eq 1.business_days.ago.to_date
      expect(kase.current_state).to eq 'drafting'
    end

    scenario 'creating a trigger SAR' do
      create_sar(flag: 'disclosure')
      expect(admin_cases_page).to be_displayed
      expect(admin_cases_page.case_list.count).to eq 1
      kase = Case::SAR.first
      expect(BusinessUnit.dacu_disclosure).to be_in(kase.approving_teams)
    end

    scenario 'creating a trigger SAR in pending_dacu_clearance' do
      create_sar(target_state: 'pending_dacu_disclosure_clearance', flag: 'disclosure')
      expect(admin_cases_page).to be_displayed
      expect(admin_cases_page.case_list.count).to eq 1
      kase = Case::SAR.first
      expect(BusinessUnit.dacu_disclosure).to be_in(kase.approving_teams)
    end

    scenario 'creating a trigger SAR in awaiting_dispatch' do
      create_sar(target_state: 'awaiting_dispatch', flag: 'disclosure')
      expect(admin_cases_page).to be_displayed
      expect(admin_cases_page.case_list.count).to eq 1
      kase = Case::SAR.first
      expect(BusinessUnit.dacu_disclosure).to be_in(kase.approving_teams)
    end
  end

  def create_foi(case_type:, target_state:, flag: nil)
    stub_s3_uploader_for_all_files!
    find_or_create :default_press_officer
    find_or_create :default_private_officer
    admin_cases_page.load
    # save_and_open_page
    admin_cases_page.create_case_button.click
    admin_cases_new_page.create_link_for_correspondence('FOI').click

    admin_cases_new_foi_page.make_radio_button_choice(case_type)

    case flag
      when 'disclosure'
        admin_cases_new_foi_page.flag_for_disclosure_specialists.set(true)
      when 'private'
        admin_cases_new_foi_page.flag_for_private_office.set(true)
    end

    admin_cases_new_foi_page.target_state.select target_state
    admin_cases_new_foi_page.submit_button.click
    expect(admin_cases_page).to be_displayed
    expect(admin_cases_page.case_list.count).to eq 1

    Case::Base.first
  end

  def create_sar(target_state: 'drafting' ,flag: nil)
    admin_cases_page.load
    admin_cases_page.create_case_button.click
    admin_cases_new_page.create_link_for_correspondence('SAR').click
    admin_cases_new_sar_page.target_state.select target_state
    case flag
      when 'disclosure'
      admin_cases_new_sar_page.flag_for_disclosure_specialists.set(true)
    end
    admin_cases_new_sar_page.submit_button.click
    expect(admin_cases_page).to be_displayed
    expect(admin_cases_page.case_list.count).to eq 1
  end
end
