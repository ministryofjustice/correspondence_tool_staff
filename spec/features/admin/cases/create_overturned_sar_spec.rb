require "rails_helper"
require Rails.root.join("db/seeders/case_closure_metadata_seeder")

# rubocop:disable RSpec/BeforeAfterAll
xfeature "creating ICO Overturned SAR case" do
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

  def create_ico_overturned_sar(target_state: nil, flag: nil)
    stub_s3_uploader_for_all_files!

    admin_cases_page.load
    admin_cases_page.create_case_button.click
    admin_cases_new_page.create_link_for_correspondence("Overturned SAR").click
    expect(admin_cases_new_overturned_sar_page).to be_displayed

    if target_state
      admin_cases_new_overturned_sar_page.target_state.select(target_state)
    end

    case flag
    when "disclosure"
      admin_cases_new_overturned_sar_page.flag_for_disclosure_specialists.set(true)
    end

    admin_cases_new_overturned_sar_page.submit_button.click
    expect(admin_cases_page).to be_displayed
    expect(admin_cases_page).to have_case_list count: 3

    overturned_sar_row = admin_cases_page.case_list[0]
    expect(overturned_sar_row.number).to have_text("Case/Overturned ICO/SAR")
    expect(overturned_sar_row.status.text).to eq "Closed"

    ico_appeal_row = admin_cases_page.case_list[1]
    expect(ico_appeal_row.number).to have_text("SAR Appeal")
    expect(ico_appeal_row.status.text).to eq "Closed"

    sar_case_row = admin_cases_page.case_list[2]
    expect(sar_case_row.number).to have_text("SAR")
    expect(sar_case_row.status.text).to eq "Closed"
  end

  context "when Case::OverturnedICO::SAR" do
    scenario "creating a case with the default values" do
      create_ico_overturned_sar(target_state: "closed")
    end

    scenario "creating a trigger case" do
      create_ico_overturned_sar(target_state: "closed", flag: "disclosure")
    end
  end
end
# rubocop:enable RSpec/BeforeAfterAll
