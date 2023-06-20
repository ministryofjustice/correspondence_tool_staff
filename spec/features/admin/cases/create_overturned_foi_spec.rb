require "rails_helper"
require File.join(Rails.root, "db", "seeders", "case_closure_metadata_seeder")

feature "creating ICO Overturned FOI case" do
  given(:admin) { create :admin }

  before(:all) do
    CaseClosure::MetadataSeeder.seed!
  end

  after(:all) do
    CaseClosure::MetadataSeeder.unseed!
  end

  before do
    CTS.class_eval do
      @dacu_manager = nil
      @dacu_team = nil
    end
    create :responding_team
    find_or_create :team_dacu

    login_as admin
  end

  def create_ico_overturned_foi(target_state: nil, flag: nil)
    stub_s3_uploader_for_all_files!

    admin_cases_page.load
    admin_cases_page.create_case_button.click
    admin_cases_new_page.create_link_for_correspondence("Overturned FOI").click
    expect(admin_cases_new_overturned_foi_page).to be_displayed

    if target_state
      admin_cases_new_overturned_foi_page.target_state.select(target_state)
    end

    case flag
    when "disclosure"
      admin_cases_new_overturned_foi_page.flag_for_disclosure_specialists.set(true)
    when "private"
      admin_cases_new_overturned_foi_page.flag_for_private_office.set(true)
    end

    admin_cases_new_overturned_foi_page.submit_button.click
    expect(admin_cases_page).to be_displayed
    expect(admin_cases_page.case_list.count).to eq 3

    overturned_foi_row = admin_cases_page.case_list[0]
    expect(overturned_foi_row.number).to have_text("Overturned ICO appeal for FOI")
    expect(overturned_foi_row.status.text).to eq "Closed"

    ico_appeal_row = admin_cases_page.case_list[1]
    expect(ico_appeal_row.number).to have_text("FOI Appeal")
    expect(ico_appeal_row.status.text).to eq "Closed"

    foi_case_row = admin_cases_page.case_list[2]
    expect(foi_case_row.number).to have_text("FOI")
    expect(foi_case_row.status.text).to eq "Closed"
  end

  context "when Case::OverturnedICO::FOI" do
    scenario "creating a case with the default values" do
      create_ico_overturned_foi(target_state: "closed")
    end

    scenario "creating a trigger case" do
      create_ico_overturned_foi(target_state: "closed", flag: "disclosure")
    end
  end
end
