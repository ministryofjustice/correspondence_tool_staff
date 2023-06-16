require "rails_helper"

feature "offender sar complaint case creation by a manager" do
  given(:manager) { find_or_create :branston_user }

  background do
    find_or_create :team_branston
    login_as manager
    CaseClosure::MetadataSeeder.seed!
  end

  after do
    CaseClosure::MetadataSeeder.unseed!
  end

  context "Standard offender sar complaint case", js: true do
    let(:offender_sar_complaint) { create(:offender_sar_complaint).decorate }

    before do
      cases_page.load
      cases_show_page.load(id: offender_sar_complaint.id)
    end

    scenario "progressing an offender sar complaint case - scenario 1" do
      to_be_assessed
      requires_data_review
      requires_response
      close_case
    end

    scenario "progressing an offender sar complaint case - scenario 2" do
      to_be_assessed
      requires_data_review
      vetting_in_progress
      ready_to_copy
      requires_response
      close_case
    end

    scenario "progressing an offender sar complaint case - scenario 3" do
      to_be_assessed
      requires_response
      close_case
    end

    scenario "progressing an offender sar complaint case - scenario 4" do
      to_be_assessed
      requires_data
      waiting_for_data
      requires_response
      close_case
    end

    scenario "progressing an offender sar complaint case - scenario 5" do
      to_be_assessed
      requires_data
      waiting_for_data
      ready_for_vetting
      vetting_in_progress
      ready_to_copy
      requires_response
      close_case
    end
  end

  context "ICO offender sar complaint case", js: true do
    let(:offender_sar_complaint) { create(:offender_sar_complaint, complaint_type: "ico_complaint").decorate }

    before do
      cases_page.load
      cases_show_page.load(id: offender_sar_complaint.id)
    end

    scenario "progressing an offender sar complaint case - scenario 1" do
      to_be_assessed
      requires_data_review
      requires_response
      close_case
    end

    scenario "progressing an offender sar complaint case - scenario 2" do
      to_be_assessed
      requires_data_review
      vetting_in_progress
      ready_to_copy
      requires_response
      close_case
    end

    scenario "progressing an offender sar complaint case - scenario 3" do
      to_be_assessed
      requires_response
      close_case
    end

    scenario "progressing an offender sar complaint case - scenario 4" do
      to_be_assessed
      requires_data
      waiting_for_data
      requires_response
      close_case
    end

    scenario "progressing an offender sar complaint case - scenario 5" do
      to_be_assessed
      requires_data
      waiting_for_data
      ready_for_vetting
      vetting_in_progress
      ready_to_copy
      requires_response
      close_case
    end
  end

  context "Litigation offender sar complaint case", js: true do
    let(:offender_sar_complaint) { create(:offender_sar_complaint, complaint_type: "litigation_complaint").decorate }

    before do
      cases_page.load
      cases_show_page.load(id: offender_sar_complaint.id)
    end

    scenario "progressing an offender sar complaint case - scenario 1" do
      to_be_assessed
      requires_data_review
      requires_response
      legal_proceedings_ongoing
      close_case
    end

    scenario "progressing an offender sar complaint case - scenario 2" do
      to_be_assessed
      requires_data_review
      vetting_in_progress
      ready_to_copy
      ready_to_dispatch
      legal_proceedings_ongoing
      close_case
    end

    scenario "progressing an offender sar complaint case - scenario 3" do
      to_be_assessed
      requires_response
      legal_proceedings_ongoing
      close_case
    end

    scenario "progressing an offender sar complaint case - scenario 4" do
      to_be_assessed
      requires_data
      waiting_for_data
      ready_for_vetting
      vetting_in_progress
      ready_to_copy
      ready_to_dispatch
      legal_proceedings_ongoing
      close_case
    end
  end

private

  def to_be_assessed
    expect(cases_show_page).to have_content "Requires data"
    expect(cases_show_page).to have_content "Requires data review"
    expect(cases_show_page).to have_content "Requires response"
    expect(cases_show_page).to have_content "To be assessed"
    expect(cases_show_page).to have_content "Send acknowledgement letter"
  end

  def waiting
    click_on "Mark as waiting"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Requires data"
    expect(cases_show_page).to have_content "Send acknowledgement letter"
  end

  def requires_data_review
    click_on "Requires data review"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as vetting in progress"
    expect(cases_show_page).to have_content "Requires response"
    expect(cases_show_page).to have_content "Send acknowledgement letter"
    expect(cases_show_page).to have_content "Data review is required"
  end

  def requires_data
    click_on "Requires data"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as waiting for data"
    expect(cases_show_page).to have_content "Data to be requested"
    expect(cases_show_page).to have_content "Send acknowledgement letter"
  end

  def waiting_for_data
    click_on "Mark as waiting for data"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready for vetting"
    if offender_sar_complaint.complaint_type != "Litigation"
      expect(cases_show_page).to have_content "Requires response"
    end
    expect(cases_show_page).to have_content "Preview cover page"
  end

  def ready_for_vetting
    click_on "Mark as ready for vetting"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as vetting in progress"
    expect(cases_show_page).to have_content "Preview cover page"
    expect(cases_show_page).to have_content "Ready for vetting"
  end

  def vetting_in_progress
    click_on "Mark as vetting in progress"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ready to copy"
    expect(cases_show_page).to have_content "Preview cover page"
    expect(cases_show_page).to have_content "Vetting in progress"
  end

  def ready_to_copy
    click_on "Mark as ready to copy"

    expect(cases_show_page).to be_displayed
    if offender_sar_complaint.complaint_type == "Litigation"
      expect(cases_show_page).to have_content "Mark as ready to dispatch"
    else
      expect(cases_show_page).to have_content "Requires response"
    end
  end

  def requires_response
    click_on "Requires response"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Response is required"

    if offender_sar_complaint.complaint_type == "ICO"
      expect(cases_show_page).to have_content "Close"
      expect(cases_show_page).to have_content "Add approval"
      expect(cases_show_page).to have_content "Add outcome"
    end
    if offender_sar_complaint.complaint_type == "Standard"
      expect(cases_show_page).to have_content "Close"
    end
    if offender_sar_complaint.complaint_type == "Litigation"
      expect(cases_show_page).to have_content "Mark as ongoing legal case"
    end
  end

  def ready_to_dispatch
    click_on "Mark as ready to dispatch"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Mark as ongoing legal case"
  end

  def legal_proceedings_ongoing
    click_on "Mark as ongoing legal case"

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Close"

    if offender_sar_complaint.complaint_type == "Litigation"
      expect(cases_show_page).to have_content "Add approval"
      expect(cases_show_page).to have_content "Add outcome"
      expect(cases_show_page).to have_content "Add costs"
    end
  end

  def close_case
    click_on "Close case"

    expect(cases_close_page).to be_displayed
    cases_close_page.fill_in_date_responded(Time.zone.today)
    click_on "Continue"

    expect(cases_closure_outcomes_page).not_to be_displayed

    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content "Closed"
    expect(cases_show_page).to have_content "Send dispatch letter"
    if offender_sar_complaint.complaint_type == "Litigation"
      expect(cases_show_page).to have_content "Add approval"
      expect(cases_show_page).to have_content "Add outcome"
      expect(cases_show_page).to have_content "Add costs"
    end

    if offender_sar_complaint.complaint_type == "ICO"
      expect(cases_show_page).to have_content "Add approval"
      expect(cases_show_page).to have_content "Add outcome"
    end
  end
end
