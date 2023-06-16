require "rails_helper"

feature "filtering cases" do
  before(:all) do
    login_as create(:manager)
    @unassigned_case             = create :sar_case
    @awaiting_responder_case     = create :awaiting_responder_sar
    @drafting_case               = create :accepted_sar
    @pending_dacu_clearance_case = create :pending_dacu_clearance_sar
  end

  after(:all) { DbHousekeeping.clean }

  before { sign_in create(:manager) }

  let(:all_case_numbers) do
    case_nos(@unassigned_case,
             @awaiting_responder_case,
             @drafting_case,
             @pending_dacu_clearance_case)
  end

  scenario "no checkboxes selected before filter applied", js: true do
    open_cases_page.load
    open_cases_page.case_filters.filter_cases_link.click
    open_cases_page.case_filters.filter_open_status_link.click
    open_cases_page.case_filters.apply_filters_button.click
    expect(open_cases_page.case_numbers).to match_array(all_case_numbers)
  end

  scenario "filter just unassigned cases", js: true do
    open_cases_page.load
    open_cases_page.case_filters.filter_cases_link.click
    open_cases_page.case_filters.filter_open_status_link.click
    open_cases_page.choose_state("unassigned")
    open_cases_page.case_filters.apply_filters_button.click

    expect(open_cases_page.case_numbers).to eq [@unassigned_case.number]
  end

  scenario "filter on unassigned, drafting and awaiting_dispatch cases", js: true do
    open_cases_page.load
    open_cases_page.case_filters.filter_cases_link.click
    open_cases_page.case_filters.filter_open_status_link.click
    open_cases_page.choose_state("unassigned")
    open_cases_page.choose_state("drafting")
    open_cases_page.choose_state("awaiting_dispatch")
    open_cases_page.case_filters.apply_filters_button.click

    expected_case_nos = case_nos(@unassigned_case,
                                 @drafting_case)
    expect(open_cases_page.case_numbers).to match_array(expected_case_nos)
  end

  scenario "just pending dacu clearance", js: true do
    open_cases_page.load
    open_cases_page.case_filters.filter_cases_link.click
    open_cases_page.case_filters.filter_open_status_link.click
    open_cases_page.choose_state("pending_dacu_clearance")
    open_cases_page.case_filters.apply_filters_button.click

    expected_case_nos = [@pending_dacu_clearance_case.number]

    expect(open_cases_page.case_numbers).to match_array(expected_case_nos)
  end

  def case_nos(*args)
    result = []
    args.each do |kase|
      result << kase.number
    end
    result
  end
end
